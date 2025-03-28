# frozen_string_literal: true

class Booking < ApplicationRecord
  extend Enumerize

  belongs_to :admin_user

  enumerize :gym, in: Gym::NAMES, scope: :shallow, predicates: { prefix: true }

  validates :gym, presence: true
  validates :starts_at, presence: true, uniqueness: { scope: %i[admin_user_id gym] }
end

# == Schema Information
#
# Table name: bookings
#
#  id            :bigint           not null, primary key
#  gym           :string           default("crc"), indexed => [starts_at, admin_user_id]
#  starts_at     :datetime         not null, indexed => [admin_user_id, gym]
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  admin_user_id :bigint           not null, indexed, indexed => [starts_at, gym]
#
# Indexes
#
#  index_bookings_on_admin_user_id                        (admin_user_id)
#  index_bookings_on_starts_at_and_admin_user_id_and_gym  (starts_at,admin_user_id,gym) UNIQUE
#
