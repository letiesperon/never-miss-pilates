# frozen_string_literal: true

module CRC
  class LoginRequest
    AUTHENTICATION_URL = 'https://services.mywellness.com/Application/ec1d38d7-d359-48d0-a60c-d8c0b8fb9df9/Login'

    HEADERS = {
      'Accept' => 'application/json',
      'X-MWAPPS-OAUTHTOKEN' => '20250123202740|8491e24fc6e345c647eb2c6de0eb0dea64fd1513',
      'X-MWAPPS-CLIENT' => 'mywellnessappios40',
      'X-MWAPPS-APPID' => 'ec1d38d7-d359-48d0-a60c-d8c0b8fb9df9',
      'User-Agent' => 'MywellnessCustom/13 CFNetwork/1568.200.51 Darwin/24.1.0',
      'X-MWAPPS-CLIENTVERSION' => '6.7.12.13,crcgym,6.7.12.5,iPhone14.5,18.1.1',
      'Content-Type' => 'application/json'
    }.freeze

    include AppService

    attr_reader :response

    def initialize(email:, password:)
      @email = email
      @password = password
    end

    def make_request
      make_httparty_request
      set_response_errors
      report_errors
      log_request_summary
    rescue StandardError => e
      handle_error(e)
    end

    def success?
      !!(success_code? && user_id && token.present?)
    end

    def user_id
      return unless success_code?

      response_body.fetch('data').fetch('userContext').fetch('id')
    rescue KeyError => e
      ErrorHandling.notify(e)
      nil
    end

    def token
      return unless success_code?

      response_body.fetch('token')
    rescue KeyError => e
      ErrorHandling.notify(e)
      nil
    end

    private

    attr_reader :email, :password

    def make_httparty_request
      @response = HTTParty.post(
        AUTHENTICATION_URL,
        body: {
          keepMeLoggedIn: true,
          password: password,
          username: email
        }.to_json,
        headers: HEADERS
      )
    end

    def set_response_errors
      if !success_code?
        add_error(:base, "Authentication request failed with status code: #{response_code}")
      elsif !user_id || !token
        add_error(:base, 'Could not extract user_id and/or token from login response body')
      end
    end

    def report_errors
      return if success?

      ErrorHandling.warn(errors.full_messages)
    end

    def log_request_summary
      Rails.logger.info('[CRC] [LoginRequest] Request summary', request_summary_h)
    end

    def handle_error(e)
      Rails.logger.error("[CRC] [LoginRequest] Unexpected exception: #{e.message}")
      ErrorHandling.notify(e)
      add_error(:base, 'Unexpected error occurred')
    end

    def success_code?
      response_code == 200
    end

    def response_code
      response&.code
    end

    def response_body
      response&.parsed_response
    end

    def request_summary_h
      {
        email: email,
        code: response&.code,
        response_body:
      }
    end
  end
end
