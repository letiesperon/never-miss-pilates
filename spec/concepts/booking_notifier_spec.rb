# frozen_string_literal: true

RSpec.describe BookingNotifier do
  let(:booking) { create(:booking, admin_user:) }
  let(:admin_user) { create(:admin_user, phone_number: '1234567890') }

  describe '::Worker' do
    it_behaves_like 'enqueues a job' do
      let(:job_class) { described_class::Worker }
      let(:trigger) { job_class.perform_async(booking.id) }
    end

    describe '#perform' do
      subject(:perform) { described_class::Worker.new.perform(booking.id) }

      let!(:notifier_double) do
        stub_class(described_class,
                   params: [booking:],
                   methods: { notify!: nil })
      end

      it 'calls the charger' do
        perform

        expect(notifier_double).to have_received(:notify!)
      end
    end
  end

  describe '#notify!' do
    let(:response) {}
    let(:booking_notifier) { described_class.new(booking:) }

    let(:stubbed_response) do
      instance_double(HTTParty::Response, code: 200)
    end

    before do
      allow(HTTParty).to receive(:post).and_return(stubbed_response)
    end

    context 'when env vars are set and admin has phone' do
      before do
        stub_const('BookingNotifier::WHATSAPP_ACCOUNT_ID', 'valid_account_id')
        stub_const('BookingNotifier::WHATSAPP_ACCESS_TOKEN', 'valid_token')
      end

      it 'sends a WhatsApp message and logs success' do
        booking_notifier.notify!

        expect(HTTParty).to have_received(:post).with(
          'https://graph.facebook.com/v21.0/valid_account_id/messages',
          headers: {
            'Authorization' => 'Bearer valid_token',
            'Content-Type' => 'application/json'
          },
          body: {
            messaging_product: 'whatsapp',
            to: '1234567890',
            type: 'template',
            template: {
              name: 'booking_confirmation',
              language: {
                code: 'en_US'
              }
            }
          }.to_json
        )
      end
    end

    context 'when the phone number is missing' do
      let(:admin_user) { create(:admin_user, phone_number: nil) }

      it 'does not send a message' do
        booking_notifier.notify!

        expect(HTTParty).not_to have_received(:post)
      end
    end

    context 'when environment variables are missing' do
      before do
        stub_const('BookingNotifier::WHATSAPP_ACCOUNT_ID', nil)
        stub_const('BookingNotifier::WHATSAPP_ACCESS_TOKEN', nil)
      end

      it 'does not send a message' do
        booking_notifier.notify!

        expect(HTTParty).not_to have_received(:post)
      end
    end
  end
end
