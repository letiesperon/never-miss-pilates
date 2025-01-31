class ChangeUniqIndexOnBookings2 < ActiveRecord::Migration[7.1]
  def change
    remove_index :bookings, name: 'index_bookings_on_starts_at_and_admin_user_id'
    add_index :bookings, %i[starts_at admin_user_id gym], unique: true
  end
end
