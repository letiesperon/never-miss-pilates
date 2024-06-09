# frozen_string_literal: true

class OneScrapper
  include Capybara::DSL
  include AppService

  attr_reader :booking_succeeded

  class ClassNotBookableError < StandardError
    def skip_bugsnag?
      true
    end
  end

  def initialize(desired_booking)
    @desired_booking = desired_booking
    @booking_succeeded = nil
  end

  def process
    return if already_booked?

    log_start
    select_date
    select_time

    with_lock_on_desired_booking do
      next if already_booked?

      confirm_booking
      record_booking
    end

    log_success
  rescue ClassNotBookableError => e
    handle_class_not_bookable(e)
  end

  private

  attr_reader :desired_booking

  delegate :date, :time, :date_s, :datetime, to: :booking_datetime

  def already_booked?
    Booking.exists?(starts_at: datetime)
  end

  def booking_datetime
    @booking_datetime ||= NextDatetimeCalculator.next_datetime(desired_booking)
  end

  def with_lock_on_desired_booking(&)
    desired_booking.with_lock(&)
  end

  def log_start
    Rails.logger.info("[Scrapper] Starting to book class for #{datetime}")
  end

  def select_date
    Rails.logger.info("[Scrapper] About to click on date: #{date_s}")

    selector = "div[data-date='#{date_s}']"

    Rails.logger.info("[Scrapper] Waiting for date element: #{selector}")
    raise "Date element #{selector} not found" unless page.has_selector?(selector, wait: 90)

    element = find(selector)
    class_list = element[:class]

    # this appears for non-bookable slots:
    raise ClassNotBookableError, "Date #{date} is not bookable" if class_list.include?('prev-date')

    Rails.logger.info("[Scrapper] Date #{date} is bookable")
    span_element = element.find('span')
    raise 'Span element not found within the date element' unless span_element

    element.click
    span_element.click # TODO. sometimes clicking in both is needed, sometimes it closes the modal.
    Rails.logger.info('[Scrapper] Clicked on date element')
  end

  def select_time
    Rails.logger.info("[Scrapper] About to choose time: #{time}")

    Rails.logger.info("[Scrapper] Waiting for timeslot containing the text: #{time}")
    raise "Timeslot for #{time} not found" unless page.has_content?(time, wait: 90)

    timeslot = find('span.timeslot-range', text: time)
    button = timeslot.find(:xpath,
                           "./ancestor::div[contains(@class, 'timeslot')]//button[contains(@class, 'new-appt button')]")
    raise "'Reservar Turno' button not found for the timeslot #{time}" unless button

    Rails.logger.info("[Scrapper] Clicking 'Reservar Turno' button for timeslot #{time}")
    button.click
    Rails.logger.info("[Scrapper] Clicked on 'Reservar Turno' button")
  end

  def confirm_booking
    Rails.logger.info('[Scrapper] Confirming booking...')

    unless page.has_selector?('#submit-request-appointment', wait: 30)
      raise "'Confirmo Reserva' button not found"
    end

    find('#submit-request-appointment').click
  end

  def log_success
    Rails.logger.info("[Scrapper] Successfully booked class for #{datetime}")
  end

  def record_booking
    Booking.find_or_create_by!(starts_at: datetime)
  end

  def handle_class_not_bookable(e)
    Rails.logger.info("[Scrapper] Class for #{datetime} is not bookable")
    add_error(:base, e.message)
  end
end
