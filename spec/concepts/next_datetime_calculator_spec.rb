# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NextDatetimeCalculator, type: :model do
  before do
    # Today is January 1st, 2025: WEDNESDAY
    travel_to Time.zone.parse('2025-01-01 12:00:00')
  end

  describe '.next_datetime' do
    subject(:result) { described_class.next_datetime(desired_booking) }

    let(:desired_booking) { build(:desired_booking, day_of_week:, time:) }

    let(:day_of_week) {}
    let(:time) {}

    context 'when day_of_week matches today and the time has not passed' do
      let(:day_of_week) { 'wednesday' }
      let(:time) { '12:10' }

      it "returns today's date with the specified time" do
        expect(result.datetime).to eq(Time.zone.parse('2025-01-01 12:10:00'))
      end
    end

    context 'when day_of_week matches today but the time has already passed' do
      let(:day_of_week) { 'wednesday' }
      let(:time) { '11:30' }

      it "returns the next week's same day with the specified time" do
        expect(result.datetime).to eq(Time.zone.parse('2025-01-08 11:30:00'))
      end
    end

    context 'when day_of_week is a later day in the week' do
      let(:day_of_week) { 'thursday' }
      let(:time) { '08:00' }

      it "returns this week's day with the specified time" do
        expect(result.datetime).to eq(Time.zone.parse('2025-01-02 08:00:00'))
      end
    end

    context 'when day_of_week is earlier in the week' do
      let(:day_of_week) { 'tuesday' }
      let(:time) { '21:35' }

      it "returns next week's day with the specified time" do
        expect(result.datetime).to eq(Time.zone.parse('2025-01-07 21:35:00'))
      end
    end
  end
end
