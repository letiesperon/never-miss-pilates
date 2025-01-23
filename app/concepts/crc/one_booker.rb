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

        if admin_user_has_no_credentials?
          log_skipped_no_credentials
          next
        end

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

    def admin_user_has_no_credentials?
      crc_token.blank? || crc_user_id.blank?
    end

    def crc_token
      desired_booking.admin_user.crc_token
    end

    def crc_user_id
      desired_booking.admin_user.crc_user_id
    end

    def log_skipped_no_credentials
      Rails.logger.info('[CRC] [Booker] Skipped booking due to missing credentials', debugging_hash)
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
        request = CRC::BookRequest.new(
          **{
            datetime: datetime,
            station:,
            crc_token: admin_user.crc_token,
            crc_user_id: admin_user.crc_user_id
          }.compact # compact in case station is nil
        )

        request.make_request

        if request.succeeded?
          record_booking
          log_success
        end

        break unless request.place_not_available?
      end
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

    def debugging_hash
      {
        datetime: datetime,
        crc_user_id: crc_user_id
      }.merge(desired_booking.to_log_hash)
    end
  end
end
