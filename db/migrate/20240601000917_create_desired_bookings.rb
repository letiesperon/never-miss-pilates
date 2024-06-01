class CreateDesiredBookings < ActiveRecord::Migration[7.1]
  def change
    create_table :desired_bookings do |t|
      t.string :day_of_week, null: false
      t.integer :hour, null: false
      t.boolean :enabled, null: false, default: true

      t.timestamps
    end

    add_index :desired_bookings, %i[day_of_week hour], unique: true
  end
end
