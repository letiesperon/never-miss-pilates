class AddCrcSettingsToAdminUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :admin_users, :crc_user_id, :string
    add_column :admin_users, :crc_token, :string
  end
end
