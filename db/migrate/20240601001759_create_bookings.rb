class CreateBookings < ActiveRecord::Migration[7.1]
  def change
    create_table :bookings do |t|
      t.datetime :starts_at, null: false

      t.timestamps
    end

    add_index :bookings, :starts_at, unique: true
  end
end
