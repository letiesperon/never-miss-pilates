# frozen_string_literal: true

# This helper simplifies the stubbing of classes and mailers that are used within the class we are testing.
# It provides two main methods: `stub_class` and `stub_mailer`.

# Usage example for an outgoing query with `stub_class`:

# before do
#   stub_class(
#     Providers::CustomersQuery,
#       methods: { get: [customer1, customer2] },
#       params: [provider:, search_term: 'mary']
#   )
# end

# You can also use the returned double to make assertions in your test:
# Don't forget to use the ! otherwise the double will not be created in time.
#
# let!(:refunder_double) do
#    stub_class(Shop::Orders::Refunder, methods: { refund!: nil }, params: [order:])
#  end
#
# The parameter `use_double` if set to true, it will use `double` instead of `instance_double`.
# The reason for this is that `double` can be used to stub methods that are not defined in the class.
# For example when we use delegate_missing_to in a class.

# it 'calls the refunder' do
#   object_under_test.do_something
#   expect(refunder_double).to have_received(:refund!)
# end

# Usage example for stubbing a mailer with `stub_mailer`:

# let!(:delivery_double) do
#   stub_mailer(
#     Registrations::ProviderMailer,
#     mailer_method: :send_notice_email,
#     params: [registration:]
#   )
# end

# it 'sends email' do
#   confirmer.confirm!

#   expect(delivery_double).to have_received(:deliver_later)
# end

# NOTE: the params are an optional array in order to support the different ways params can be passed.

# Other examples of params:

# params: 'foo' # single positional argument
# params: no_args # no arguments
# params: ['foo', 'bar'] # multiple positional arguments
# params: [foo: 'bar'] # single keyword argument
# params: [foo: 'bar', baz: 'qux'] # multiple keyword arguments
# params: [[1,2,3]] # single positional array argument

module StubbingHelper
  NOT_SPECIFIED = 'PARAMS_NOT_SPECIFIED'

  def stub_class(klass, params: NOT_SPECIFIED, methods: {}, only_positional_params: false,
                 use_double: false)
    double = use_double ? double(klass, ** methods) : instance_double(klass, ** methods)

    if params == NOT_SPECIFIED
      allow(klass).to receive(:new).and_return(double)
    else
      positional_args, keyword_args = extract_params(params, only_positional_params)
      allow(klass).to receive(:new).with(*positional_args, **keyword_args).and_return(double)
    end

    double
  end

  def stub_mailer(klass, mailer_method:, params: NOT_SPECIFIED, only_positional_params: false)
    double = instance_double(ActionMailer::MessageDelivery, deliver_later: nil, deliver_now: nil)

    if params == NOT_SPECIFIED
      allow(klass).to receive(mailer_method).and_return(double)
    else
      positional_args, keyword_args = extract_params(params, only_positional_params)
      allow(klass).to receive(mailer_method).with(*positional_args,
                                                  **keyword_args).and_return(double)
    end

    double
  end

  private

  def extract_params(params, only_positional_params)
    return [Array(params), {}] if only_positional_params
    return extract_params_from_array(params) if params.is_a?(Array)

    positional_args = [params]

    [positional_args, {}]
  end

  def extract_params_from_array(params_array)
    params_copy = params_array.dup
    keyword_args = params_copy.last.is_a?(Hash) ? params_copy.pop : {}
    [params_copy, keyword_args]
  end
end
