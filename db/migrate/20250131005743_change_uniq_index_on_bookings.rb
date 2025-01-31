class ChangeUniqIndexOnBookings < ActiveRecord::Migration[7.1]
  def change
    remove_index :bookings, name: 'index_bookings_on_starts_at'
    add_index :bookings, %i[starts_at admin_user_id], unique: true
  end
end
