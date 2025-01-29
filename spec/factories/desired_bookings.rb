# frozen_string_literal: true

FactoryBot.define do
  factory :desired_booking do
    gym { Gym::NAMES.sample }
    day_of_week { %i[monday tuesday wednesday thursday friday saturday sunday].sample }
    time { Faker::Time.backward }
    enabled { Faker::Boolean.boolean }

    preferred_stations do
      Array.new(Faker::Number.between(from: 1, to: 5)) do
        Faker::Number.between(from: 1, to: 20)
      end
    end

    admin_user

    trait :crc do
      gym { 'crc' }
    end
  end
end
