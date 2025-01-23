class AddCrcColumns < ActiveRecord::Migration[7.1]
  def change
    add_column :desired_bookings, :gym, :string
    add_column :bookings, :gym, :string
    DesiredBooking.update_all(gym: 'clt')
    Booking.update_all(gym: 'clt')

    change_column_default :desired_bookings, :gym, 'crc'
    change_column_default :bookings, :gym, 'crc'
  end
end
