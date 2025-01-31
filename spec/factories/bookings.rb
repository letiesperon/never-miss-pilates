# frozen_string_literal: true

FactoryBot.define do
  factory :booking do
    gym { Gym::NAMES.sample }
    starts_at { Faker::Time.between(from: 1.hour.from_now, to: 2.weeks.from_now) }
    admin_user

    trait :crc do
      gym { 'crc' }
    end
  end
end
