class AddCRCCredentialsToAdminUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :admin_users, :crc_email, :string
    add_column :admin_users, :crc_password, :string
  end
end
