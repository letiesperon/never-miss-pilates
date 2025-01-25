# frozen_string_literal: true

require 'active_job'
require 'active_support/testing/time_helpers'
require 'sidekiq/testing'

RSpec.configure do |config|
  config.include ActiveJob::TestHelper
  config.include ActiveSupport::Testing::TimeHelpers

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
    mocks.verify_doubled_constant_names = true
  end

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended. For more details, see:
  # https://relishapp.com/rspec/rspec-core/docs/configuration/zero-monkey-patching-mode
  config.disable_monkey_patching!

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = 'doc'
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 3

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed

  config.before do
    ActionMailer::Base.deliveries.clear
    ActiveJob::Base.queue_adapter = :test
    Faker::UniqueGenerator.clear
  end

  # Uncomment the following line if you want to print the names of each test that runs
  # when running the entire suite.
  # Useful for when you want to figure out what specific test is printing a warning:
  # config.formatter = :documentation

  config.after do
    FileUtils.rm_rf(Dir[Rails.root.join('/spec/support/uploads').to_s])
    FileUtils.rm_rf(Dir[Rails.root.join('/tmp/storage').to_s])
    travel_back
  end
end
