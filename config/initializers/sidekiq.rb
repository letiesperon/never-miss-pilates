# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq/web'
require 'sidekiq-unique-jobs'

Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  Rack::Utils.secure_compare(Digest::SHA256.hexdigest(user), Digest::SHA256.hexdigest(ENV.fetch('SIDEKIQ_USER', nil))) &
    Rack::Utils.secure_compare(Digest::SHA256.hexdigest(password), Digest::SHA256.hexdigest(ENV.fetch('SIDEKIQ_PASSWORD', nil)))
end

Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV.fetch('REDIS_URL', nil),
    ssl_params: {
      verify_mode: OpenSSL::SSL::VERIFY_NONE
    }
  }

  config.death_handlers << lambda { |job, ex|
    args = job['args']
    context = args.present? ? { api_name: args.first, global_id: args.second, additional_args: args.third } : {}
    ErrorHandling.notify(ex, context)
  }

  config.logger = Rails.logger

  # Log worker Class name and JID:
  config.logger.before_log = lambda do |data|
    ctx = Thread.current[:sidekiq_context]
    break unless ctx

    items = ctx.map { |c| c.split(' ') }.flatten
    data[:sidekiq_context] = items if items.any?
  end

  config.error_handlers << lambda do |ex, ctx|
    Sidekiq.logger.warn(ex, job: ctx[:job])
  end

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  SidekiqUniqueJobs::Server.configure(config)
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV.fetch('REDIS_URL', nil),
    ssl_params: {
      verify_mode: OpenSSL::SSL::VERIFY_NONE
    }
  }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

# The following makes sure all sidekiq jobs are pushed
# only after the DB transaction has committed:
Sidekiq.transactional_push!

# NOTE. Need to disable sidekiq unique jobs in tests, otherwise integration tests
# that try to run the same job twice will fail (second time does not execute)
# https://github.com/sidekiq/sidekiq/issues/3513 :
SidekiqUniqueJobs.configure { |config| config.enabled = !Rails.env.test? }
