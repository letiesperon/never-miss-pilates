# frozen_string_literal: true

RSpec.describe CRC::BookRequest do
  subject(:book_request) do
    described_class.new(datetime:, class_id:, station:, crc_token:, crc_user_id:)
  end

  let(:datetime) { Time.current }
  let(:class_id) { 'class-1234' }
  let(:station) { 1 }
  let(:crc_token) { 'valid_token' }
  let(:crc_user_id) { '123' }

  let(:response) {}

  before do
    allow(HTTParty).to receive(:post).and_return(response)
    allow(ErrorHandling).to receive(:notify)
    allow(ErrorHandling).to receive(:warn)
  end

  context 'when the booking is successful' do
    let(:response) do
      instance_double(HTTParty::Response, code: 200, parsed_response: { 'result' => 'Booked' })
    end

    it 'makes a POST request to the booking URL with correct body and headers' do
      book_request.make_request

      expect(HTTParty).to have_received(:post).with(
        CRC::BookRequest::BOOKING_URL,
        body: {
          classId: 'class-1234',
          station: station,
          partitionDate: datetime.strftime('%Y%m%d').to_i,
          userId: crc_user_id
        }.to_json,
        headers: { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{crc_token}" }
      )

      expect(book_request.success?).to be(true)
      expect(book_request.already_booked?).to be(false)
      expect(book_request.unauthorized?).to be(false)
      expect(book_request.place_not_available?).to be(false)

      expect(ErrorHandling).not_to have_received(:notify)
      expect(ErrorHandling).not_to have_received(:warn)
    end
  end

  context 'when the user is already booked' do
    let(:response) do
      instance_double(HTTParty::Response,
                      code: 200,
                      parsed_response: { 'result' => 'UserAlreadyBooked' })
    end

    it 'identifies the booking as already booked' do
      book_request.make_request

      expect(book_request.success?).to be(false)
      expect(book_request.already_booked?).to be(true)
      expect(book_request.unauthorized?).to be(false)
      expect(book_request.place_not_available?).to be(false)

      expect(ErrorHandling).not_to have_received(:notify)
      expect(ErrorHandling).not_to have_received(:warn)
    end
  end

  context 'when the place is not available' do
    let(:response) do
      instance_double(HTTParty::Response,
                      code: 200,
                      parsed_response: { 'result' => 'PlaceNotAvailable' })
    end

    it 'identifies the booking as place not available' do
      book_request.make_request

      expect(book_request.success?).to be(false)
      expect(book_request.already_booked?).to be(false)
      expect(book_request.unauthorized?).to be(false)
      expect(book_request.place_not_available?).to be(true)

      expect(ErrorHandling).not_to have_received(:notify)
      expect(ErrorHandling).not_to have_received(:warn)
    end
  end

  context 'when the request is unauthorized' do
    let(:response) { instance_double(HTTParty::Response, code: 401, parsed_response: {}) }

    it 'identifies the request as unauthorized' do
      book_request.make_request

      expect(book_request.success?).to be(false)
      expect(book_request.unauthorized?).to be(true)
      expect(book_request.already_booked?).to be(false)
      expect(book_request.place_not_available?).to be(false)

      expect(ErrorHandling).not_to have_received(:notify)
      expect(ErrorHandling).not_to have_received(:warn)
    end
  end

  context 'when an unexpected response occurs' do
    let(:response) do
      instance_double(HTTParty::Response, code: 500, parsed_response: { 'result' => 'ServerError' })
    end

    it 'logs a warning for the unexpected response' do
      book_request.make_request

      expect(book_request.success?).to be(false)
      expect(book_request.already_booked?).to be(false)
      expect(book_request.unauthorized?).to be(false)
      expect(book_request.place_not_available?).to be(false)

      expect(ErrorHandling).to have_received(:warn).with(
        '[CRC] [BookRequest] Unexpected response',
        response: { code: 500, body: { 'result' => 'ServerError' } }
      )
    end
  end

  context 'when an exception occurs' do
    before do
      allow(HTTParty).to receive(:post).and_raise(StandardError, 'test error')
    end

    it 'notifies the error' do
      expect { book_request.make_request }.not_to raise_error

      expect(book_request.success?).to be(false)
      expect(book_request.already_booked?).to be(false)
      expect(book_request.place_not_available?).to be(false)
      expect(book_request.unauthorized?).to be(false)

      expect(ErrorHandling).to have_received(:notify).with(instance_of(StandardError))
    end
  end
end
