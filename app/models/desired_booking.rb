# frozen_string_literal: true

class DesiredBooking < ApplicationRecord
  extend Enumerize

  enumerize :day_of_week, in: %i[monday tuesday wednesday thursday friday saturday sunday],
                          predicates: true

  validates :day_of_week, presence: true

  validates :hour,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 24 },
            uniqueness: { scope: :day_of_week }

  validates :enabled, inclusion: { in: [true, false] }

  scope :enabled, -> { where(enabled: true) }
end

# == Schema Information
#
# Table name: desired_bookings
#
#  id          :bigint           not null, primary key
#  day_of_week :string           not null, indexed => [hour]
#  enabled     :boolean          default(TRUE), not null
#  hour        :integer          not null, indexed => [day_of_week]
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_desired_bookings_on_day_of_week_and_hour  (day_of_week,hour) UNIQUE
#
