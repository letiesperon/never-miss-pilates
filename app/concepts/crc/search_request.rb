# frozen_string_literal: true

module CRC
  class SearchRequest
    SEARCH_URL = 'https://calendar.mywellness.com/v2/enduser/class/search'

    def initialize(date:)
      @date = date
    end

    def make_request
      make_httparty_request
      validate_array_response!
    rescue StandardError => e
      handle_error(e)
      nil
    end

    def response_body
      response&.parsed_response
    end

    private

    attr_reader :date, :response

    def make_httparty_request
      @response = HTTParty.get(
        SEARCH_URL,
        query: {
          facilityId: ::Gym::CRC_FACILITY_ID,
          eventTypes: 'Class',
          fromDate: formatted_date,
          toDate: formatted_date
        },
        headers: { 'Content-Type' => 'application/json' }
      )
    end

    def formatted_date
      date.strftime('%Y-%m-%d')
    end

    def validate_array_response!
      return if response.code == 200 && response.parsed_response.is_a?(Array)

      raise InvalidResponseError,
            "Unexpected search request response. #{response.code} - #{response.parsed_response}"
    end

    def handle_error(e)
      Rails.logger.error("[CRC] [SearchRequest] Unexpected exception: #{e.message}")
      ErrorHandling.notify(e)
    end
  end
end
