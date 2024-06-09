require 'capybara'
require 'capybara/dsl'
require 'selenium-webdriver'

class CapybaraScraper
  USERNAME = ENV.fetch('CLT_USERNAME')
  PASSWORD = ENV.fetch('CLT_PASSWORD')
  HEADLESS = ENV.fetch('HEADLESS', 'true') == 'true'

  include Capybara::DSL

  def initialize(booking_datetime)
    @booking_datetime = booking_datetime

    Capybara.register_driver :selenium do |app|
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument('--headless') if HEADLESS
      options.add_argument('--disable-gpu')
      options.add_argument('--no-sandbox')
      options.add_argument('--disable-dev-shm-usage')

      Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
    end

    Capybara.default_driver = :selenium
    Capybara.app_host = 'https://cltapp.club/reformer/pilates-reformer/'
  end

  def book
    Rails.logger.info("Starting booking process for #{datetime}")

    visit('/')
    login
    verify_login
    select_date
    select_time
    confirm_booking
  rescue => e
    Rails.logger.error("Failed to book class for #{datetime}: #{e.message}")
    raise e
  end

  private

  attr_reader :booking_datetime

  delegate :date, :time, :date_s, :datetime, to: :booking_datetime

  def login
    Rails.logger.info('Navigating to login page')
    fill_in 'username', with: USERNAME
    fill_in 'password', with: PASSWORD
    check 'rememberme'
    find('input[name="login"]').click
  end

  def verify_login
    Rails.logger.info("Logged in. Checking for 'Pilates Reformer'")
    if page.has_content?('Pilates Reformer', wait: 100)
      Rails.logger.info("'Pilates Reformer' is visible on the screen")
    else
      raise "Login failed or 'Pilates Reformer' not found"
    end
  end

  def select_date
    Rails.logger.info("About to click on date: #{date_s}")

    selector = "div[data-date='#{date_s}']"

    Rails.logger.info("Waiting for date element: #{selector}")
    if page.has_selector?(selector, wait: 60)
      element = find(selector)
      class_list = element[:class]
      if !class_list.include?('prev-date') # this appears for non-bookable slots
        Rails.logger.info("Date #{date} is bookable")
        span_element = element.find('span')
        if span_element
          element.click
          span_element.click
          Rails.logger.info("Clicked on date element")
          sleep 2
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

    Rails.logger.info("Waiting for timeslot containing the text: #{time}")
    if page.has_content?(time, wait: 60)
      timeslot = find("span.timeslot-range", text: time)
      button = timeslot.find(:xpath, "./ancestor::div[contains(@class, 'timeslot')]//button[contains(@class, 'new-appt button')]")
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
    sleep 2
  end

  def confirm_booking
    Rails.logger.info("Confirming booking")
    if page.has_selector?('#submit-request-appointment', wait: 10)
      find('#submit-request-appointment').click
      Rails.logger.info("Successfully booked class for #{booking_datetime}")
    else
      Rails.logger.info("'Confirmo Reserva' button not found")
      raise "'Confirmo Reserva' button not found"
    end
    sleep 5
  end

  def day_to_number(day)
    %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].index(day)
  end
end
