# frozen_string_literal: true

Bugsnag.configure do |config|
  config.api_key = ENV.fetch('BUGSNAG_API_KEY', nil)
  config.app_version = ENV.fetch('HEROKU_RELEASE_VERSION', nil)
  config.release_stage = ENV['BUGSNAG_RELEASE_STAGE'] || ENV.fetch('RAILS_ENV', nil)
  config.enabled_release_stages = %w[production staging review]
end
