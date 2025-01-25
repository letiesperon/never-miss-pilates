# frozen_string_literal: true

module CRC
  class Authenticator
    include AppService

    def initialize(admin_user:)
      @admin_user = admin_user
    end

    def authenticate
      validate_crc_credentials
      return if failure?

      make_login_request
      validate_request
      return if failure?

      store_crc_token_in_admin_user
    end

    private

    attr_reader :admin_user, :request

    def validate_crc_credentials
      return if crc_email.present? && crc_password.present?

      add_error(:base, 'CRC email and/or password missing')
    end

    delegate :crc_email, :crc_password, to: :admin_user

    def make_login_request
      @request = LoginRequest.new(email: crc_email, password: crc_password)
      request.make_request
    end

    def validate_request
      return if request.success?

      add_errors(request.errors)
    end

    def store_crc_token_in_admin_user
      admin_user.update!(crc_token: request.token, crc_user_id: request.user_id)
    end
  end
end
