# frozen_string_literal: true

module CLT
  class AllScraper
    PILATES_URL = 'https://cltapp.club/reformer/pilates-reformer/'
    USERNAME = ENV.fetch('CLT_USERNAME')
    PASSWORD = ENV.fetch('CLT_PASSWORD')
    DEFAULT_RETRIES = 20
    TIME_RANGE_BETWEEN_RETRIALS = 3..10
    HEADLESS = ENV.fetch('HEADLESS', 'true') == 'true'

    class Worker
      include Sidekiq::Worker

      sidekiq_options queue: :high, retry: false

      def perform(retries = DEFAULT_RETRIES)
        AllScraper.new(retries:).perform
      end
    end

    include Capybara::DSL
    include AppService

    def initialize(retries: DEFAULT_RETRIES)
      @retries = retries
      initialize_capybara
    end

    def perform
      log_start

      begin
        visit_pilates_page
        login_if_needed
        try_many_times
        log_end
      rescue => e
        handle_unexpected_exception(e)
      ensure
        quit_driver
      end
    end

    private

    attr_reader :retries

    def initialize_capybara
      Capybara.register_driver :selenium_chrome do |app|
        options = ::Selenium::WebDriver::Chrome::Options.new
        options.add_argument('--headless=new') if HEADLESS
        options.add_argument('--disable-gpu')
        options.add_argument('--no-sandbox')
        options.add_argument('--disable-dev-shm-usage')
        options.add_argument('window-size=1920,1080')
        options.add_argument('--remote-debugging-port=9230')

        Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
      end

      Capybara.default_driver = :selenium_chrome
      Capybara.app_host = PILATES_URL
    end

    def log_start
      Rails.logger.info('[AllScraper] Starting booking perform')
    end

    def login_if_needed
      if logged_in?
        Rails.logger.info('[AllScraper] Already logged in. Skipping login.')
      elsif seeing_login_form?
        login
      else
        raise '[AllScraper] Login form not found. But also not logged in.'
      end
    end

    def logged_in?
      page.has_content?('Pilates Reformer', wait: 90) &&
        page.has_content?('Docentes:', wait: 10)
    end

    def seeing_login_form?
      page.has_content?('Nombre de usuario', wait: 90)
    end

    def login
      Rails.logger.info('About to submit login form')

      fill_in 'username', with: USERNAME
      fill_in 'password', with: PASSWORD
      check 'rememberme'

      find('input[name="login"]').click

      verify_is_logged_in
    end

    def verify_is_logged_in
      Rails.logger.info("[AllScraper] Logged in. Checking for 'Pilates Reformer'")

      raise "Login failed or 'Pilates Reformer' not found" unless logged_in?

      Rails.logger.info("[AllScraper] 'Pilates Reformer' is visible on the screen")
    end

    def try_many_times
      (1..retries).each do |i|
        break if no_bookings?

        log_try(i)
        try_each_desired_booking
        next if i == retries # (no need to sleep if it's the last try)

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
      DesiredBooking.clt.enabled
    end

    def log_try(i)
      Rails.logger.info("[AllScraper] Attempt ##{i} to book classes")
    end

    def try_each_desired_booking
      pending_bookings.find_each do |desired_booking|
        scraper = OneScraper.new(desired_booking)
        scraper.perform
        add_errors(scraper.errors)
      end
    end

    def sleep_random
      random = rand(TIME_RANGE_BETWEEN_RETRIALS)
      Rails.logger.info("[AllScraper] Sleeping for #{random} seconds before retrying")
      sleep(random)
    end

    def visit_pilates_page
      Rails.logger.info("[AllScraper] Visiting Pilates page: #{PILATES_URL}")
      visit('/')
    end

    def handle_unexpected_exception(e)
      Rails.logger.error("[AllScraper] Unexpected exception: #{e.message}")
      add_error(:base, e.inspect)
      ErrorHandling.notify(e)
    end

    def quit_driver
      Capybara.current_session&.driver&.quit
      Capybara.current_session.reset!
    rescue => e
      Rails.logger.warn("[AllScraper] Could not quit driver: #{e.message}")
      ErrorHandling.notify(e)
    end

    def log_end
      Rails.logger.info('[AllScraper] Finished')
    end
  end
end
