# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.2'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.1.0'
# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'
# Use Puma as the app server
gem 'puma'

gem 'rack-timeout'

gem 'after_commit_everywhere'
gem 'bcrypt'
gem 'bugsnag'
gem 'encryption'
gem 'enumerize', '~> 2.3', '>= 2.3.1'
gem 'oj'
gem 'redis'

# Background jobs:
gem 'sidekiq'
gem 'sidekiq-scheduler'
gem 'sidekiq-unique-jobs'

gem 'with_advisory_lock'

# Backoffice:
gem 'activeadmin'
gem 'activeadmin_addons' # Extra features like search select https://github.com/platanus/activeadmin_addons
gem 'active_skin' # Theme
gem 'capybara' # UI tests
gem 'devise', '~> 4.9.3'
gem 'draper' # Decorators
gem 'jb' # Override JSON route views
gem 'sassc-rails'
gem 'sprockets-rails'

gem 'selenium-webdriver'
gem 'capybara-screenshot'
gem 'webdrivers'

# Logging:
# Compact Rails controller logs in a single log per request:
gem 'lograge'
gem 'lograge-sql'
# Puma is multithreaded, so lograge-sql doc recommends adding request_store gem.
# Lograge will pick it up. See https://github.com/iMacTia/lograge-sql#thread-safety.
gem 'request_store'
# Ougai is used to structure logs in JSON format:
gem 'amazing_print'
gem 'ougai'

# Application Performance Monitoring:
gem 'newrelic_rpm'

# Allow adding color to puts statements:
gem 'colorize'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'

# NOTE. It's required in all envs because there's an initializer that uses it.
gem 'faker'

# Suppress warnings:
gem 'warning', '~> 1.3.0'

group :development, :test do
  gem 'bundler-audit'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'rspec-rails', '~> 6.1.1'
end

group :development do
  gem 'annotate'
  gem 'bullet'
  gem 'listen'
  gem 'pry'
  gem 'pry-awesome_print'
  gem 'pry-rails'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'ruby-prof'
  gem 'spring'
  gem 'spring-watcher-listen'
end

group :test do
  gem 'shoulda-matchers', '~> 6.1.0'
  gem 'simplecov'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
