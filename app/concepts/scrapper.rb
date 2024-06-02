require 'playwright'

class Scrapper
  USERNAME = ENV.fetch('CLT_USERNAME')
  PASSWORD = ENV.fetch('CLT_PASSWORD')

  include AppService

  def initialize(booking_datetime)
    @booking_datetime = booking_datetime
  end

  def book
    Rails.logger.info("Starting booking process for #{datetime}")

    with_playwright do |page|
      # @page = page
      login
      verify_login
      select_date
      select_time
      confirm_booking
    end
  rescue => e
    add_error(:base, e.message)
    raise e
  end

  private

  attr_reader :booking_datetime, :page

  delegate :date, :time, :date_s, :datetime, to: :booking_datetime

  def with_playwright
    Playwright.create(playwright_cli_executable_path: './node_modules/.bin/playwright') do |playwright|
      browser = playwright.chromium.launch(headless: false)
      context = browser.new_context
      @page = context.new_page

      begin
        yield
      rescue => e
        Rails.logger.error("Failed to book class for #{datetime}: #{e}")
        raise e
      ensure
        browser.close
      end
    end
  end

  def login
    Rails.logger.info('Navigating to login page')
    page.goto('https://cltapp.club/reformer/pilates-reformer/')
    Rails.logger.info('Filling in username and password')
    page.fill('#username', USERNAME)
    page.fill('#password', PASSWORD)
    page.click('#rememberme')
    page.click('input[name="login"]')
  end

  def verify_login
    Rails.logger.info("Logged in. Checking for 'Pilates Reformer'")
    page.wait_for_selector("h1:has-text('Pilates Reformer')", timeout: 100_000)
    Rails.logger.info("'Pilates Reformer' is visible on the screen")
  end

  def select_date
    Rails.logger.info("About to click on date: #{date_s}")

    selector = "div[data-date='#{date_s}']"

    Rails.logger.info("Waiting for date element: #{selector}")
    page.wait_for_selector(selector, timeout: 60000)

    element = page.query_selector(selector)

    if element
      class_list = element.get_attribute('class')
      if !class_list.include?('prev-date') # this appears for non-bookable slots
        Rails.logger.info("Date #{date} is bookable")
        span_element = element.query_selector('span')
        if span_element
          element.click
          span_element.click
          span_element.click
          Rails.logger.info("Clicked on date element")
          page.wait_for_timeout(2000)
        else
          Rails.logger.info("Span element not found within the date element")
          raise "Span element not found within the date element"
        end
      else
        Rails.logger.info("Date #{date} is not bookable")
        raise "Date #{date} is not bookable"
      end
    else
      Rails.logger.info("Date element #{selector} not found")
      raise "Date element #{selector} not found"
    end
  end

  def select_time
    Rails.logger.info("About to choose time: #{time}")

    # Wait for the timeslots to appear
    Rails.logger.info("Waiting for timeslot containing the text: #{time}")
    page.wait_for_selector("span.timeslot-range:has-text('#{time}')", timeout: 60000)

    # Find the specific timeslot
    timeslot = page.query_selector("span.timeslot-range:has-text('#{time}')")

    if timeslot
      Rails.logger.info("Found timeslot for #{time}")
      # Find the "Reservar Turno" button after the timeslot
      button = timeslot.evaluate_handle("node => node.closest('div.timeslot').querySelector('button.new-appt.button')")

      if button
        Rails.logger.info("Clicking 'Reservar Turno' button for timeslot #{time}")
        button.click
        Rails.logger.info("Clicked on 'Reservar Turno' button")
      else
        Rails.logger.info("'Reservar Turno' button not found for the timeslot #{time}")
        raise "'Reservar Turno' button not found for the timeslot #{time}"
      end
    else
      Rails.logger.info("Timeslot for #{time} not found")
      raise "Timeslot for #{time} not found"
    end
    page.wait_for_timeout(2000)
  end

  def confirm_booking
    Rails.logger.info("Confirming booking")
    page.wait_for_selector("#submit-request-appointment", timeout: 10000)
    Rails.logger.info("'Confirmo Reserva' button is visible on the screen")
    page.click("#submit-request-appointment")
    page.wait_for_timeout(5000)
    Rails.logger.info("Successfully booked class for #{booking_datetime}")
  end

  def day_to_number(day)
    %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].index(day)
  end
end
