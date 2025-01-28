# frozen_string_literal: true

RSpec.describe DesiredBooking, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:admin_user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:gym) }
    it { is_expected.to validate_presence_of(:day_of_week) }
    it { is_expected.to validate_presence_of(:hour) }

    it {
      is_expected.to validate_numericality_of(:hour)
        .only_integer
        .is_greater_than_or_equal_to(0)
        .is_less_than(24)
    }

    it { is_expected.to validate_inclusion_of(:enabled).in_array([true, false]) }
  end

  describe '.enabled' do
    let!(:booking_enabled) { create(:desired_booking, enabled: true) }
    let!(:booking_disabled) { create(:desired_booking, enabled: false) }

    it 'returns only enabled bookings' do
      expect(described_class.enabled).to contain_exactly(booking_enabled)
    end
  end

  describe '#preferred_stations=' do
    let(:booking) { build(:desired_booking) }

    it 'splits string into array if input is string' do
      booking.preferred_stations = '1, 2, 3'
      expect(booking.preferred_stations).to eq([1, 2, 3])
    end

    it 'sets array directly if input is array' do
      booking.preferred_stations = %w[1 2 3]
      expect(booking.preferred_stations).to eq([1, 2, 3])
    end
  end

  describe '#to_log_hash' do
    let(:admin_user) { create(:admin_user, email: 'example@example.com') }

    let(:booking) do
      create(:desired_booking,
             admin_user:,
             gym: 'crc',
             day_of_week: 'monday',
             hour: 8,
             enabled: true, preferred_stations: [1, 2])
    end

    it 'returns a hash with booking and admin details' do
      expect(booking.to_log_hash).to eq({
                                          desired_booking_id: booking.id,
                                          admin_user: 'example@example.com',
                                          gym: 'crc',
                                          day_of_week: 'monday',
                                          hour: 8,
                                          enabled: true,
                                          preferred_stations: [1, 2]
                                        })
    end
  end
end
