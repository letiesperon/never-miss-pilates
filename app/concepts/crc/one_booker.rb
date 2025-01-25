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
        next if already_booked?

        validate_credentials_present
        next if failure?

        if too_far_in_advance?
          log_skipped_too_far_in_advance
          next
        end

        make_booking
      end
    end

    private

    attr_reader :desired_booking

    def with_lock_on_desired_booking(&)
      desired_booking.with_lock(&)
    end

    def already_booked?
      Booking.exists?(starts_at: datetime,
                      gym: desired_booking.gym,
                      admin_user: desired_booking.admin_user)
    end

    delegate :admin_user, to: :desired_booking

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

    def crc_token
      desired_booking.admin_user.crc_token
    end

    def crc_user_id
      desired_booking.admin_user.crc_user_id
    end

    def too_far_in_advance?
      datetime > BOOKINGS_OPEN_IN_ADVANCE.from_now
    end

    def log_skipped_too_far_in_advance
      Rails.logger.info('[CRC] [Booker] Skipped booking due to being too far in advance',
                        debugging_hash)
    end

    def log_start
      Rails.logger.info('[CRC] [Booker] Starting to book class', debugging_hash)
    end

    def make_booking
      stations.each do |station|
        2.times do
          request = book_request(station)
          request.make_request

          if request.success? || request.already_booked?
            record_booking
            log_success
            return
          elsif request.unauthorized?
            authenticate
            unless success?
              log_failed_authentication
              return
            end
            next # Retry the same station after re-authenticating
          elsif request.place_not_available?
            break # Move to the next station
          else
            log_bad_request
            return # Exit entirely on bad request
          end
        end
      end
    end

    def book_request(station)
      CRC::BookRequest.new(
        datetime: datetime,
        station: station,
        crc_token: admin_user.crc_token,
        crc_user_id: admin_user.crc_user_id
      )
    end

    def log_failed_authentication
      Rails.logger.error('[CRC] [Booker] Failed to authenticate user', debugging_hash)
    end

    def log_bad_request
      Rails.logger.error('[CRC] [Booker] Bad request', debugging_hash)
    end

    def stations
      # adding nil as a last option so that CRC automatically assigns a spot
      (desired_booking.preferred_stations || []) << nil
    end

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

    def debugging_hash
      {
        datetime: datetime,
        crc_user_id: crc_user_id
      }.merge(desired_booking.to_log_hash)
    end
  end
end
