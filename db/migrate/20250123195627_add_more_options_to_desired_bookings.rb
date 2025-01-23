class AddMoreOptionsToDesiredBookings < ActiveRecord::Migration[7.1]
  def change
    add_column :desired_bookings, :preferred_stations, :integer, array: true
  end
end
