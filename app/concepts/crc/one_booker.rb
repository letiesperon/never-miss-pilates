# frozen_string_literal: true

module CRC
  class OneBooker
    include AppService

    BOOKINGS_OPEN_IN_ADVANCE = 24.hours

    def initialize(desired_booking)
      @desired_booking = desired_booking
    end

    def perform
      with_lock_on_desired_booking do
        log_start

        if already_booked?
          log_already_booked
          return
        end

        validate_credentials_present
        next if failure?

        if too_far_in_advance?
          log_skipped_too_far_in_advance
          next
        end

        find_class_id
        attempt_bookings
      end
    end

    private

    attr_reader :desired_booking, :class_id, :book_request

    delegate :admin_user, to: :desired_booking
    delegate :crc_token, :crc_user_id, to: :admin_user

    def with_lock_on_desired_booking(&)
      desired_booking.with_lock(&)
    end

    def log_start
      Rails.logger.info('[CRC] [Booker] Starting to process booking', debugging_hash)
    end

    def already_booked?
      Booking.exists?(starts_at: datetime,
                      gym: desired_booking.gym,
                      admin_user: desired_booking.admin_user)
    end

    def log_already_booked
      Rails.logger.info('[CRC] [Booker] Skipping because already booked', debugging_hash)
    end

    def booking_datetime
      @booking_datetime ||= NextDatetimeCalculator.next_datetime(desired_booking)
    end

    delegate :date, :time, :date_s, :datetime, to: :booking_datetime

    def validate_credentials_present
      return unless admin_user_has_no_credentials?

      Rails.logger.info('[CRC] [Booker] Missing credentials', debugging_hash)
      add_error(:base, 'Admin user is missing CRC credentials')
    end

    def admin_user_has_no_credentials?
      crc_token.blank? || crc_user_id.blank?
    end

    def too_far_in_advance?
      datetime > BOOKINGS_OPEN_IN_ADVANCE.from_now
    end

    def log_skipped_too_far_in_advance
      Rails.logger.info('[CRC] [Booker] Skipped booking due to being too far in advance',
                        debugging_hash)
    end

    def find_class_id
      class_finder = CRC::ClassFinder.new(datetime:)
      class_finder.find!
      @class_id = class_finder.class_id
    end

    def attempt_bookings
      stations.each do |station|
        # Repeating 2 times because if unauthorized,
        # we need to retry the same station after re-authenticating:
        2.times do
          make_book_request(station)

          if book_request_succeeded?
            record_booking
            log_success
            return # Exit entirely
          elsif book_request_unauthorized?
            authenticate
            unless success?
              log_failed_authentication
              return # Exit entirely
            end
            next # Retry the same station after re-authenticating
          elsif book_request_place_not_available?
            break # Move to the next station
          else
            log_bad_request
            return # Exit entirely
          end
        end
      end
    end

    def stations
      # adding nil as a last option so that CRC automatically assigns a spot if the user
      # doesn't have a preference or all preferred stations are full
      (desired_booking.preferred_stations || []) << nil
    end

    def make_book_request(station)
      @book_request = CRC::BookRequest.new(
        datetime: datetime,
        class_id:,
        station: station,
        crc_token: admin_user.crc_token,
        crc_user_id: admin_user.crc_user_id
      )

      book_request.make_request
    end

    def book_request_succeeded?
      book_request.success? || book_request.already_booked?
    end

    delegate :unauthorized?, :place_not_available?, to: :book_request, prefix: true

    def record_booking
      Booking.find_or_create_by!(starts_at: datetime,
                                 admin_user: desired_booking.admin_user,
                                 gym: desired_booking.gym)
    end

    def log_success
      Rails.logger.info('[CRC] Successfully booked class', debugging_hash)
    end

    def authenticate
      authenticator = CRC::Authenticator.new(admin_user: admin_user)
      authenticator.authenticate

      return if authenticator.success?

      add_errors(authenticator.errors)
    end

    def log_failed_authentication
      Rails.logger.error('[CRC] [Booker] Failed to authenticate user', debugging_hash)
    end

    def log_bad_request
      Rails.logger.error('[CRC] [Booker] Bad request', debugging_hash)
    end

    def debugging_hash
      {
        datetime: datetime,
        crc_user_id: crc_user_id
      }.merge(desired_booking.to_log_hash)
    end
  end
end
