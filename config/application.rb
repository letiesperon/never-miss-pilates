# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_mailbox/engine'
require 'action_text/engine'
require 'action_view/railtie'
require 'action_cable/engine'
require 'sprockets/railtie'
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module VillageApi
  class Application < Rails::Application
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.eager_load_paths << Rails.root.join("extras")

    config.time_zone = 'America/Montevideo'

    config.active_job.queue_adapter = :sidekiq

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = false

    # config.action_mailer.delivery_method = :sendgrid_actionmailer
    # config.action_mailer.sendgrid_actionmailer_settings = {
    #   api_key: ENV.fetch('SEND_GRID_KEY', nil),
    #   raise_delivery_errors: true,
    #   perform_send_request: true
    # }

    config.active_storage.track_variants = false
    config.active_storage.variant_processor = :vips

    console do
      require 'amazing_print'
      AmazingPrint.irb!
    end

    # This is needed for ActiveAdmin until they implement another fix:
    # https://github.com/heartcombo/devise/issues/5443
    config.session_store :cookie_store, key: '_interslice_session'
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use config.session_store, config.session_options
  end
end
