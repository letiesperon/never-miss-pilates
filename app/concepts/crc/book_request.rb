# frozen_string_literal: true

# NOTE. If trying to book a date that is for example 2 days ahead we'll get: 200ok and
# { "result": "EventNotExists" }

module CRC
  class BookRequest
    BOOKING_URL = 'https://calendar.mywellness.com/v2/enduser/class/book'
    SUCCESS_RESULT = 'Booked'
    ALREADY_BOOKED_RESULT = 'AlreadyBooked'
    PLACE_NOT_AVAILABLE_RESULT = 'PlaceNotAvailable'

    attr_reader :response

    def initialize(datetime:, class_id:, station:, crc_token:, crc_user_id:)
      @datetime = datetime
      @class_id = class_id
      @station = station
      @crc_token = crc_token
      @crc_user_id = crc_user_id
    end

    def make_request
      make_httparty_request
      report_errors
      log_request_summary
    rescue StandardError => e
      handle_error(e)
    end

    def success?
      response_code == 200 && result_value == SUCCESS_RESULT
    end

    def already_booked?
      response_code == 200 && result_value == ALREADY_BOOKED_RESULT
    end

    def unauthorized?
      response_code == 401
    end

    def place_not_available?
      result_value == PLACE_NOT_AVAILABLE_RESULT
    end

    private

    attr_reader :datetime, :class_id, :station, :crc_token, :crc_user_id

    def make_httparty_request
      @response = HTTParty.post(
        BOOKING_URL,
        body: {
          classId: class_id,
          station:,
          partitionDate: partition_date,
          userId: crc_user_id
        }.to_json,
        headers: { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{crc_token}" }
      )
    end

    def partition_date
      # We have to send in YYYYMMDD (eg '20250124' for January 24th, 2025)
      datetime.strftime('%Y%m%d').to_i
    end

    def report_errors
      return if success? || already_booked? || unauthorized? || place_not_available?

      ErrorHandling.warn('[CRC] [BookRequest] Unexpected response',
                         response: { code: response_code, body: response_body })
    end

    def log_request_summary
      Rails.logger.info('[CRC] [BookRequest] Request summary', request_summary_h)
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

    def handle_error(e)
      Rails.logger.error("[CRC] [BookRequest] Unexpected exception: #{e.message}")
      ErrorHandling.notify(e)
    end
  end
end
