# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CRC::Authenticator do
  subject(:authenticator) { described_class.new(admin_user: admin_user) }

  let(:admin_user) { create(:admin_user, crc_email:, crc_password:) }
  let(:crc_email) { 'test@example.com' }
  let(:crc_password) { 'password' }

  before do
    stub_class(CRC::LoginRequest,
               params: [
                 email: crc_email,
                 password: crc_password
               ],
               methods: {
                 make_request: nil
               })
  end

  context 'when the CRC credentials are missing' do
    let(:crc_email) { nil }
    let(:crc_password) { nil }

    it 'adds an error and does not proceed with the request' do
      authenticator.authenticate

      expect(authenticator).to be_failure
      expect(authenticator.errors).to eq(base: 'CRC email and/or password missing')
    end
  end

  context 'when the login request is successful' do
    before do
      stub_class(CRC::LoginRequest,
                 params: [
                   email: crc_email,
                   password: crc_password
                 ],
                 methods: {
                   make_request: nil,
                   success?: true,
                   token: 'fake_token',
                   user_id: '123'
                 })
    end

    it 'stores the CRC token and user ID in the admin user' do
      authenticator.authenticate

      expect(authenticator).to be_success
      expect(admin_user.reload).to have_attributes(crc_token: 'fake_token', crc_user_id: '123')
    end
  end

  context 'when the login request fails' do
    before do
      stub_class(CRC::LoginRequest,
                 params: [
                   email: crc_email,
                   password: crc_password
                 ],
                 methods: {
                   make_request: nil,
                   success?: false,
                   errors: { base: 'Random error foobar' }
                 })
    end

    it 'adds errors from the login request and does not store the CRC token' do
      authenticator.authenticate

      expect(authenticator).to be_failure
      expect(authenticator.errors).to eq(base: 'Random error foobar')
    end
  end
end
