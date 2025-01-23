# frozen_string_literal: true

module CRC
  class AllBooker
    class Worker
      include Sidekiq::Worker

      sidekiq_options queue: :high, retry: false

      def perform
        AllBooker.new.perform
      end
    end

    include AppService

    def perform
      log_start
      try_each_desired_booking
      log_end
    end

    private

    def log_start
      Rails.logger.info('[CRC AllBooker] Starting booking perform',
                        desired_bookings_count: desired_bookings.count)
    end

    def desired_bookings
      @desired_bookings ||= DesiredBooking.crc.enabled
    end

    def try_each_desired_booking
      desired_bookings.find_each do |desired_booking|
        booker = OneBooker.new(desired_booking)
        booker.perform
        add_errors(booker.errors)
      end
    end

    def handle_unexpected_exception(e)
      Rails.logger.error("[AllBooker] Unexpected exception: #{e.message}")
      add_error(:base, e.inspect)
      ErrorHandling.notify(e)
    end

    def log_end
      Rails.logger.info('[AllBooker] Finished')
    end
  end
end
