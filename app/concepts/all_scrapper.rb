# frozen_string_literal: true

class AllScrapper
  PILATES_URL = 'https://cltapp.club/reformer/pilates-reformer/'
  USERNAME = ENV.fetch('CLT_USERNAME')
  PASSWORD = ENV.fetch('CLT_PASSWORD')
  RETRIES = 20
  TIME_RANGE_BETWEEN_RETRIALS = 3..10
  HEADLESS = ENV.fetch('HEADLESS', 'true') == 'true'

  class Worker
    include Sidekiq::Worker

    sidekiq_options queue: :high, retry: false

    def perform
      AllScrapper.new.process
    end
  end

  include Capybara::DSL
  include AppService

  attr_reader :booking_succeeded

  class ClassNotBookableError < StandardError
    def skip_bugsnag?
      true
    end
  end

  def initialize
    initialize_capybara
  end

  def process
    log_start

    begin
      visit_pilates_page
      login
      verify_login
      try_many_times
    rescue => e
      handle_unexpected_exception(e)
    ensure
      quit_driver
    end
  end

  private

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
    Rails.logger.info('[AllScrapper] Starting booking process')
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

  def try_many_times
    (1..RETRIES).each do |i|
      break if no_bookings?

      log_try(i)
      try_each_desired_booking
      sleep_random
      visit_pilates_page
    rescue => e
      handle_unexpected_exception(e)
      break
    end
  end

  def no_bookings?
    pending_bookings.none?
  end

  def pending_bookings
    DesiredBooking.enabled
  end

  def log_try(i)
    Rails.logger.info("[AllScrapper] Attempt ##{i} to book classes")
  end

  def try_each_desired_booking
    pending_bookings.find_each do |desired_booking|
      scrapper = OneScrapper.new(desired_booking)
      scrapper.process
      add_errors(scrapper.errors)
    end
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

  def handle_unexpected_exception(e)
    Rails.logger.error("[AllScrapper] Unexpected exception: #{e.message}")
    @booking_succeeded = false
    add_error(:base, e.inspect)
    ErrorHandling.notify(e)
  end

  def quit_driver
    Capybara.current_session&.driver&.quit
  rescue => e
    Rails.logger.warn("[AllScrapper] Could not quit driver: #{e.message}")
    ErrorHandling.notify(e)
  end
end
