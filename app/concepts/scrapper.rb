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
      @page = page
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
    Playwright.create(playwright_cli_executable_path: 'path/to/playwright-cli') do |playwright|
      browser = playwright.chromium.launch(headless: false)
      context = browser.new_context
      @page = context.new_page

      begin
        yield
      rescue => e
        Rails.logger.error("Failed to book class for #{datetime}: #{e}")
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
    Rails.logger.info("About to click on date: #{date}")
    page.click("div[data-date='#{date}']")
    page.wait_for_timeout(20000)
  end

  def select_time
    Rails.logger.info("About to choose time: #{time}")
    page.click("div[data-time='#{time}']")
    page.wait_for_timeout(20000)
  end

  def confirm_booking
    page.click('#confirm-button')
    page.wait_for_timeout(50000)
    Rails.logger.info("Successfully booked class for #{datetime}")
  end
end
