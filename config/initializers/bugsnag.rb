# frozen_string_literal: true

Bugsnag.configure do |config|
  config.api_key = ENV['BUGSNAG_KEY']
  config.app_version = ENV['HEROKU_RELEASE_VERSION']
  config.release_stage = ENV['BUGSNAG_RELEASE_STAGE'] || ENV['RAILS_ENV']
  config.enabled_release_stages = %w[production staging review]
end
