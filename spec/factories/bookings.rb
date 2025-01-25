# frozen_string_literal: true

FactoryBot.define do
  factory :booking do
    admin_user

    trait :crc do
      gym { 'crc' }
    end
  end
end
