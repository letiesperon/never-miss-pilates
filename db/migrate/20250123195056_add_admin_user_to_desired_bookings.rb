class AddAdminUserToDesiredBookings < ActiveRecord::Migration[7.1]
  def change
    add_reference :desired_bookings, :admin_user, null: true, foreign_key: true
    DesiredBooking.update_all(admin_user_id: AdminUser.first.id)
    change_column_null :desired_bookings, :admin_user_id, false

    add_reference :bookings, :admin_user, null: true, foreign_key: true
    Booking.update_all(admin_user_id: AdminUser.first.id)
    change_column_null :bookings, :admin_user_id, false
  end
end
