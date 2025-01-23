# frozen_string_literal: true

# NOTE. If trying to book a date that is for example 2 days ahead we'll get: 200ok and
# { "result": "EventNotExists" }

module CRC
  class BookRequest
    BOOKING_URL = 'https://calendar.mywellness.com/v2/enduser/class/book'
    SUCCESS_RESULTS = %w[Booked UserAlreadyBooked].freeze
    PLACE_NOT_AVAILABLE_RESULT = 'PlaceNotAvailable'

    attr_reader :response

    def initialize(datetime:, station:, crc_token:, crc_user_id:)
      @datetime = datetime
      @station = station
      @crc_token = crc_token
      @crc_user_id = crc_user_id
    end

    def make_request
      response = HTTParty.post(
        BOOKING_URL,
        body: {
          classId: ::Gym::CRC_CYCLING_CLASS_ID,
          station:,
          partitionDate: partition_date,
          userId: crc_user_id
        }.to_json,
        headers: { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{crc_token}" }
      )

      @response = response

      Rails.logger.info('[CRC] [BookRequest] Request summary', request_summary_h)
    rescue StandardError => e
      Rails.logger.error("[CRC] [BookRequest] Unexpected exception: #{e.message}")
      ErrorHandling.notify(e)
    end

    def succeeded?
      response_code == 200 && SUCCESS_RESULTS.include?(result_value)
    end

    def unauthorized?
      response_code == 401
    end

    def place_not_available?
      result_value == PLACE_NOT_AVAILABLE_RESULT
    end

    private

    attr_reader :datetime, :station, :crc_token, :crc_user_id

    def partition_date
      # We have to send in YYYYMMDD (eg '20250124' for January 24th, 2025)
      datetime.strftime('%Y%m%d').to_i
    end

    def response_code
      response&.code
    end

    def response_body
      response&.parsed_response
    end

    def result_value
      return unless response_body.is_a?(Hash)

      response_body&.dig('result')
    end

    def request_summary_h
      {
        datetime: datetime,
        partition_date:,
        station: station,
        crc_user_id: crc_user_id,
        code: response&.code,
        result: result_value,
        response_body:
      }
    end
  end
end
