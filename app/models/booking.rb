class Booking < ApplicationRecord
  validates :starts_at, presence: true, uniqueness: true
end

# == Schema Information
#
# Table name: bookings
#
#  id         :bigint           not null, primary key
#  starts_at  :datetime         not null, indexed
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_bookings_on_starts_at  (starts_at) UNIQUE
#
