# frozen_string_literal: true

FactoryBot.define do
  factory :admin_user do
    email { Faker::Internet.email }
    password { 'Secr3t!!' }
    crc_email { Faker::Internet.email }
    crc_password { 'fooobar' }
  end
end
