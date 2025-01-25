# frozen_string_literal: true

RSpec.describe CRC::LoginRequest do
  subject(:login_request) { described_class.new(email: email, password: password) }

  let(:email) { 'test@example.com' }
  let(:password) { 'securepassword' }

  let(:response) {}

  before do
    allow(HTTParty).to receive(:post).and_return(response)
    allow(ErrorHandling).to receive(:notify)
    allow(ErrorHandling).to receive(:warn)
  end

  context 'when the response is successful' do
    let(:response) do
      instance_double(HTTParty::Response,
                      code: 200,
                      parsed_response: {
                        'token' => 'fake_token',
                        'data' => { 'userContext' => { 'id' => 123 } }
                      })
    end

    it 'makes a POST request to the authentication URL with correct body and headers' do
      login_request.make_request

      expect(HTTParty).to have_received(:post).with(
        CRC::LoginRequest::AUTHENTICATION_URL,
        body: {
          keepMeLoggedIn: true,
          password: password,
          username: email
        }.to_json,
        headers: CRC::LoginRequest::HEADERS
      )

      expect(login_request.success?).to be(true)
      expect(login_request.user_id).to eq(123)
      expect(login_request.token).to eq('fake_token')

      expect(ErrorHandling).not_to have_received(:notify)
      expect(ErrorHandling).not_to have_received(:warn)
    end
  end

  context 'when the response is unauthorized' do
    let(:response) { instance_double(HTTParty::Response, code: 401, parsed_response: {}) }

    before do
      allow(HTTParty).to receive(:post).and_return(response)
    end

    it 'returns failure' do
      login_request.make_request

      expect(login_request.success?).to be(false)
      expect(login_request.errors).to eq(base: 'Authentication request failed with status code: 401')
      expect(login_request.user_id).to be_nil
      expect(login_request.token).to be_nil

      expect(ErrorHandling).to have_received(:warn)
        .with('Authentication request failed with status code: 401')
    end
  end

  context 'when an exception occurs' do
    before do
      allow(HTTParty).to receive(:post).and_raise(StandardError, 'test error')
    end

    it 'notifies the error' do
      expect { login_request.make_request }.not_to raise_error

      expect(login_request.success?).to be(false)
      expect(login_request.errors).to eq(base: 'Unexpected error occurred')
      expect(login_request.user_id).to be_nil
      expect(login_request.token).to be_nil

      expect(ErrorHandling).to have_received(:notify).with(instance_of(StandardError))
    end
  end
end
