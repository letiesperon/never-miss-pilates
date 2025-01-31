# frozen_string_literal: true

RSpec.describe CRC::OneBooker do
  subject(:one_booker) { described_class.new(desired_booking) }

  let(:desired_booking) do
    create(:desired_booking,
           :crc,
           admin_user:,
           preferred_stations: [3, 4, 5],
           time: '8:00',
           day_of_week:)
  end

  let(:admin_user) { create(:admin_user, crc_token:, crc_user_id:) }
  let(:crc_token) { 'crc-token123' }
  let(:crc_user_id) { 'user-id-123' }

  let!(:authenticator) do
    stub_class(CRC::Authenticator,
               params: [admin_user:],
               methods: { authenticate: nil, success?: true })
  end

  let!(:class_finder) do
    stub_class(CRC::ClassFinder,
               params: [datetime: expected_booking_datetime],
               methods: { find!: nil, class_id: 'class-1234' })
  end

  let!(:book_request) do
    stub_class(CRC::BookRequest,
               params: [
                 datetime: expected_booking_datetime,
                 class_id: 'class-1234',
                 station: 3,
                 crc_token: crc_token,
                 crc_user_id: crc_user_id
               ],
               methods: {
                 make_request: nil,
                 success?: true,
                 already_booked?: false,
                 unauthorized?: false,
                 place_not_available?: false
               })
  end

  let(:day_of_week) { 'friday' }

  let(:expected_booking_datetime) do
    # Friday 3rd January 2025 8am
    Date.new(2025, 1, 3).in_time_zone('Montevideo').change(hour: 8)
  end

  let(:current_time) do
    # Thursday 2nd January 2025 8am
    Date.new(2025, 1, 2).in_time_zone('Montevideo').change(hour: 8)
  end

  before do
    travel_to(current_time)
  end

  context 'when the admin user has no credentials' do
    let(:crc_token) { nil }
    let(:crc_user_id) { nil }

    it 'errors with missing credentials' do
      expect(BookingNotifier::Worker).not_to receive(:perform_async)

      expect { one_booker.perform }.not_to change(Booking, :count)

      expect(one_booker).to be_failure
      expect(one_booker.errors).to eq(base: 'Admin user is missing CRC credentials')
      expect(authenticator).not_to have_received(:authenticate)
      expect(book_request).not_to have_received(:make_request)
    end
  end

  context 'when the booking is too far in advance' do
    let(:day_of_week) { 'monday' }

    it 'skips' do
      expect(BookingNotifier::Worker).not_to receive(:perform_async)

      expect { one_booker.perform }.not_to change(Booking, :count)

      expect(one_booker).to be_success
      expect(authenticator).not_to have_received(:authenticate)
      expect(book_request).not_to have_received(:make_request)
    end
  end

  context 'when the booking record already existed' do
    let!(:existing_booking) do
      create(:booking, :crc, starts_at: expected_booking_datetime, admin_user:)
    end

    it 'skips', :aggregate_failures do
      expect(BookingNotifier::Worker).not_to receive(:perform_async)

      expect { one_booker.perform }.not_to change(Booking, :count)

      expect(book_request).not_to have_received(:make_request)
      expect(authenticator).not_to have_received(:authenticate)
      expect(one_booker).to be_success
      expect(one_booker.errors).to be_empty
    end
  end

  context 'when booking succeeds on the first station' do
    it 'creates a new booking', :aggregate_failures do
      expect(BookingNotifier::Worker)
        .to receive(:perform_async)
        .with(an_instance_of(Integer))

      expect { one_booker.perform }.to change(Booking, :count).by(1)

      expect(book_request).to have_received(:make_request)
      expect(authenticator).not_to have_received(:authenticate)
      expect(one_booker).to be_success
      expect(one_booker.errors).to be_empty

      expect(Booking.last).to have_attributes(
        starts_at: expected_booking_datetime,
        gym: 'crc',
        admin_user: admin_user
      )
    end
  end

  context 'when all stations are unavailable' do
    before do
      [3, 4, 5, nil].each do |station|
        stub_class(CRC::BookRequest,
                   params: [
                     datetime: expected_booking_datetime,
                     class_id: 'class-1234',
                     station: station,
                     crc_token: crc_token,
                     crc_user_id: crc_user_id
                   ],
                   methods: {
                     make_request: nil,
                     success?: false,
                     already_booked?: false,
                     unauthorized?: false,
                     place_not_available?: true
                   })
      end
    end

    it 'does not create a booking' do
      expect(BookingNotifier::Worker).not_to receive(:perform_async)

      expect { one_booker.perform }.not_to change(Booking, :count)
    end
  end
end
