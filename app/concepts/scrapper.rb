require 'capybara'
require 'capybara/dsl'
require 'selenium-webdriver'

class Scrapper
  PILATES_URL = 'https://cltapp.club/reformer/pilates-reformer/'
  USERNAME = ENV.fetch('CLT_USERNAME')
  PASSWORD = ENV.fetch('CLT_PASSWORD')
  RETRIES = 20
  TIME_RANGE_BETWEEN_RETRIALS = 3..10
  HEADLESS = ENV.fetch('HEADLESS', 'true') == 'true'

  include Capybara::DSL
  include AppService

  attr_reader :booking_success

  def initialize(booking_datetime)
    @booking_datetime = booking_datetime
    @booking_success = nil

    initialize_capybara
  end

  def book
    log_start

    begin
      visit_pilates_page
      login
      verify_login
      repeat_try_book
    rescue => e
      handle_error(e)
    ensure
      quit_driver
    end
  end

  private

  attr_reader :booking_datetime

  delegate :date, :time, :date_s, :datetime, to: :booking_datetime

  def initialize_capybara
    Capybara.register_driver :selenium_chrome do |app|
      options = ::Selenium::WebDriver::Chrome::Options.new
      options.add_argument('--headless=new') if HEADLESS
      options.add_argument('--disable-gpu')
      options.add_argument('--no-sandbox')
      options.add_argument('--disable-dev-shm-usage')
      options.add_argument('window-size=1920,1080')
      options.add_argument('--remote-debugging-port=9222')

      Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
    end

    Capybara.default_driver = :selenium_chrome
    Capybara.app_host = PILATES_URL
  end

  def log_start
    Rails.logger.info("[Scrapper] Starting booking process for #{datetime}")
  end

  def login
    Rails.logger.info('About to submit login form')

    fill_in 'username', with: USERNAME
    fill_in 'password', with: PASSWORD
    check 'rememberme'

    find('input[name="login"]').click
  end

  def verify_login
    Rails.logger.info("Logged in. Checking for 'Pilates Reformer'")

    unless page.has_content?('Pilates Reformer', wait: 90)
      raise "Login failed or 'Pilates Reformer' not found"
    end

    Rails.logger.info("'Pilates Reformer' is visible on the screen")
  end

  def repeat_try_book
    (1..RETRIES).each do |i|
      log_try(i)
      select_date
      select_time
      confirm_booking
      break if booking_success
    rescue => e
      handle_error(e)
      sleep_random
      visit_pilates_page
    end
  end

  def log_try(i)
    Rails.logger.info("[Scrapper] Attempt ##{i} to book class for #{datetime}")
  end

  def select_date
    Rails.logger.info("About to click on date: #{date_s}")

    selector = "div[data-date='#{date_s}']"

    Rails.logger.info("Waiting for date element: #{selector}")
    raise "Date element #{selector} not found" unless page.has_selector?(selector, wait: 90)

    element = find(selector)
    class_list = element[:class]

    # this appears for non-bookable slots:
    raise "Date #{date} is not bookable" if class_list.include?('prev-date')

    Rails.logger.info("Date #{date} is bookable")
    span_element = element.find('span')
    raise 'Span element not found within the date element' unless span_element

    element.click
    span_element.click
    Rails.logger.info('Clicked on date element')
  end

  def select_time
    Rails.logger.info("About to choose time: #{time}")

    Rails.logger.info("Waiting for timeslot containing the text: #{time}")
    raise "Timeslot for #{time} not found" unless page.has_content?(time, wait: 90)

    timeslot = find('span.timeslot-range', text: time)
    button = timeslot.find(:xpath,
                           "./ancestor::div[contains(@class, 'timeslot')]//button[contains(@class, 'new-appt button')]")
    raise "'Reservar Turno' button not found for the timeslot #{time}" unless button

    Rails.logger.info("Clicking 'Reservar Turno' button for timeslot #{time}")
    button.click
    Rails.logger.info("Clicked on 'Reservar Turno' button")
  end

  def confirm_booking
    Rails.logger.info('Confirming booking...')

    unless page.has_selector?('#submit-request-appointment', wait: 30)
      raise "'Confirmo Reserva' button not found"
    end

    find('#submit-request-appointment').click

    set_success
  end

  def set_success
    @booking_success = true
    clear_errors
    Rails.logger.info("Successfully booked class for #{booking_datetime}")
  end

  def sleep_random
    random = rand(TIME_RANGE_BETWEEN_RETRIALS)
    Rails.logger.info("Sleeping for #{random} seconds before retrying")
    sleep(random)
  end

  def visit_pilates_page
    Rails.logger.info("Visiting Pilates page: #{PILATES_URL}")
    visit('/')
  end

  def handle_error(e)
    Rails.logger.warn("[Scrapper] Could not book class for #{datetime}: #{e.message}")
    @booking_success = false
    add_error(:base, e.inspect)
  end

  def quit_driver
    Capybara.current_session.driver.quit
  end
end
