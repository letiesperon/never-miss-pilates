# frozen_string_literal: true

require 'ougai'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Enable server timing
  config.server_timing = true

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = :amazon
  # config.active_storage.service = :local

  config.action_mailer.raise_delivery_errors = true

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true
  config.lograge_sql.keep_default_active_record_log = true

  formatter = ::Ougai::Formatters::Readable.new
  config.logger = ::Ougai::Logger.new($stdout, formatter:)

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.action_mailer.perform_deliveries = true
  config.action_mailer.default_url_options = { host: 'localhost', port: 5100 }

  routes.default_url_options[:host] = 'localhost:5100'
  config.action_cable.allowed_request_origins = [/.*/, nil]

  config.after_initialize do
    Bullet.enable = true
    Bullet.console = true
    Bullet.rails_logger = true
    Bullet.bullet_logger = true
    Bullet.bugsnag = !ENV.fetch('BULLET_BUGSNAG', false).nil?
  end
end
