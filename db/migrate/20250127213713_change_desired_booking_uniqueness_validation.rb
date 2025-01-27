class ChangeDesiredBookingUniquenessValidation < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    remove_index :desired_bookings, [:day_of_week, :hour]

    add_index :desired_bookings, %i[day_of_week hour gym admin_user_id],
      unique: true,
      name: 'index_desired_bookings_uniq_by_all',
      algorithm: :concurrently
  end
end
