# frozen_string_literal: true

class MigrateHourInDesiredBookingsToAllowMinutes < ActiveRecord::Migration[7.1]
  def change
    add_column :desired_bookings, :time, :time, null: true

    DesiredBooking.all.find_each do |desired_booking|
      desired_booking.update!(time: "#{desired_booking.hour}:00")
    end

    remove_column :desired_bookings, :hour
    change_column_null :desired_bookings, :time, false
  end
end
