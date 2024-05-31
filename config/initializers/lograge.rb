# frozen_string_literal: true

# Lograge makes Rails Controller noisy logs be summarized in a single line per request so thay
# they are easily readable and searchable in production log aggregator tools.

require 'lograge/sql/extension'

Rails.application.configure do
  config.lograge.enabled = Rails.env.production?

  config.lograge.base_controller_class = ['ActionController::API', 'ActionController::Base']

  # Disable lograge built-in formatters. Defer formatting to ougai:
  config.lograge.formatter = ->(data) { data }

  config.lograge.custom_payload do |controller|
    params = controller.try(:params) || {}

    {
      host: controller.request.host,
      user_id: controller.try(:current_user)&.id,
      admin_user_id: controller.try(:current_admin_user)&.id,
      operation_name: params[:operationName],
      query: params[:query],
      variables: filter_graphql_variables(params[:variables]),
      response: response_body(controller)
    }.compact
  end
end

def filter_graphql_variables(variables)
  return if variables.blank?

  sanitize(variables.to_unsafe_hash)
end

# NOTE. Printing the whole response in each log is not ideal for performance
# but it facilitates debugging.
def response_body(controller)
  return unless controller.try(:response)
  return if controller.response&.content_type == 'application/html'
  return unless ENV.fetch('LOG_RESPONSE_BODIES', 'true') == 'true'

  r = controller.response
  body_h = JSON.parse(r.body)

  # Sending the response as a string instead of a structured object
  # so that it appears in a single field in New Relic for better readability:
  sanitize(body_h).to_s
rescue JSON::ParserError
  nil
end

# Rails only automatically sanitizes the incoming input parameters,
# but not the custom payload we add to the log, so we need to do it manually.
def sanitize(value)
  case value
  when Hash
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    filter.filter(value)
  when Array
    value.map { |element| sanitize(element) }
  else
    nil
  end
end
