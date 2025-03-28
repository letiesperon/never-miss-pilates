# frozen_string_literal: true

class DesiredBooking < ApplicationRecord
  extend Enumerize

  belongs_to :admin_user

  enumerize :gym, in: Gym::NAMES, scope: :shallow, predicates: { prefix: true }

  enumerize :day_of_week, in: %i[monday tuesday wednesday thursday friday saturday sunday],
                          predicates: true

  validates :gym, presence: true
  validates :day_of_week, presence: true

  validates :time, presence: true

  validates :time, uniqueness: { scope: %i[day_of_week gym admin_user_id] }

  validates :enabled, inclusion: { in: [true, false] }

  scope :enabled, -> { where(enabled: true) }

  def preferred_stations=(items)
    if items.is_a? String
      super(items.split(/[\s,]+/))
    else
      super
    end
  end

  def to_log_hash
    {
      desired_booking_id: id,
      admin_user: admin_user.email,
      gym:,
      day_of_week:,
      time: time.strftime('%H:%M'),
      enabled:,
      preferred_stations:
    }
  end
end

# == Schema Information
#
# Table name: desired_bookings
#
#  id                 :bigint           not null, primary key
#  day_of_week        :string           not null
#  enabled            :boolean          default(TRUE), not null
#  gym                :string           default("crc")
#  preferred_stations :integer          is an Array
#  time               :time             not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  admin_user_id      :bigint           not null, indexed
#
# Indexes
#
#  index_desired_bookings_on_admin_user_id  (admin_user_id)
#
