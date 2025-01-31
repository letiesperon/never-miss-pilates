class AddPhoneNumberToAdminUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :admin_users, :phone_number, :string
  end
end
