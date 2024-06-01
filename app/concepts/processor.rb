# frozen_string_literal: true

class Processor
  include AppService

  class Worker
    include Sidekiq::Worker

    def perform(desired_booking_id)
      desired_booking = DesiredBooking.find(desired_booking_id)

      Processor.new(desired_booking:).process
    end
  end

  def initialize(desired_booking:)
    @desired_booking = desired_booking
  end

  def process
    return if already_booked?

    try_to_book

    if success?
      record_booking
      log_success
    else
      log_failure
    end
  end

  attr_reader :desired_booking

  def already_booked?
    Booking.exists?(starts_at: booking_datetime)
  end

  def booking_datetime
    @booking_datetime ||= DesiredBookingDecorator.next_datetime(desired_booking)
  end

  def try_to_book
    scraper = Scraper.new(booking_datetime)
    scraper.book
    add_errors(scraper.errors)
  end

  def record_booking
    Booking.create!(starts_at: booking_datetime)
  end

  def log_success
    Rails.logger.info("Booking created for #{booking_datetime}")
  end

  def log_failure
    Rails.logger.error("Booking failed for #{booking_datetime}")
  end
end
