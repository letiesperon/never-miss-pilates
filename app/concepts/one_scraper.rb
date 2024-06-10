# frozen_string_literal: true

class OneScraper
  include Capybara::DSL
  include AppService

  class ClassNotBookableError < StandardError
    def skip_bugsnag?
      true
    end
  end

  def initialize(desired_booking)
    @desired_booking = desired_booking
  end

  def perform
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
    visit_pilates_page
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
    Rails.logger.info("[Scraper] Starting to book class for #{datetime}")
  end

  def select_date
    Rails.logger.info("[Scraper] About to click on date: #{date_s}")

    selector = "div[data-date='#{date_s}']"

    Rails.logger.info("[Scraper] Waiting for date element: #{selector}")
    raise "Date element #{selector} not found" unless page.has_selector?(selector, wait: 90)

    element = find(selector)
    class_list = element[:class]

    # this appears for non-bookable slots:
    raise ClassNotBookableError, "Date #{date} is not bookable" if class_list.include?('prev-date')

    ErrorHandling.warn("Slots available on #{date} #{SecureRandom.hex(4)}", { date:, time: })

    Rails.logger.info("[Scraper] Date #{date} is bookable")
    span_element = element.find('span')
    raise 'Span element not found within the date element' unless span_element

    element.click

    Rails.logger.info('[Scraper] Clicked on date element')

    return if time_slots_opened?

    # Sometimes clicking in both is needed, sometimes it closes the slots component.
    span_element.click
    Rails.logger.info('[Scraper] Clicked on span date element (second time)')
  end

  def time_slots_opened?
    page.has_content?('Disponibles el', wait: 15)
  end

  def select_time
    Rails.logger.info("[Scraper] About to choose time: #{time}")

    Rails.logger.info("[Scraper] Waiting for timeslot containing the text: #{time}")

    raise "Timeslot for #{time} not found" unless page.has_content?(time, wait: 90)

    timeslot = find('span.timeslot-range', text: time)

    button = timeslot.find(:xpath,
                           "./ancestor::div[contains(@class, 'timeslot')]//button[contains(@class, 'new-appt button')]")

    raise "'Reservar Turno' button not found for the timeslot #{time}" unless button

    Rails.logger.info("[Scraper] Clicking 'Reservar Turno' button for timeslot #{time}")
    button.click
    Rails.logger.info("[Scraper] Clicked on 'Reservar Turno' button")
  end

  def confirm_booking
    Rails.logger.info('[Scraper] Confirming booking...')

    unless page.has_selector?('#submit-request-appointment', wait: 30)
      raise "'Confirmo Reserva' button not found"
    end

    find('#submit-request-appointment').click
  end

  def log_success
    Rails.logger.info("[Scraper] Successfully booked class for #{datetime}")
  end

  def record_booking
    Booking.find_or_create_by!(starts_at: datetime)
  end

  def visit_pilates_page
    Rails.logger.info('[Scraper] Visiting Pilates page')
    visit('/')
  end

  def handle_class_not_bookable(e)
    Rails.logger.info("[Scraper] Class for #{datetime} is not bookable")
    add_error(:base, e.message)
  end
end
