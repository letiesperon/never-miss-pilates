# frozen_string_literal: true

ActiveAdmin.register AdminUser do
  menu priority: 1
  permit_params :email, :password, :password_confirmation, :crc_user_id, :crc_token

  index do
    selectable_column
    id_column
    column :email
    column :crc_user_id
    column :current_sign_in_at
    column :sign_in_count
    column :created_at
    actions
  end

  filter :email

  show do
    attributes_table do
      row :id
      row :email
      row :crc_user_id
      row :crc_token
      row :current_sign_in_at
      row :sign_in_count
      row :created_at
      row :updated_at
      row :sign_in_count
      row :last_sign_in_ip
      row :current_sign_in_ip
      row :last_sign_in_at
      row :current_sign_in_at
    end
  end

  form do |f|
    f.inputs do
      f.input :email
      f.input :crc_user_id
      f.input :crc_token, as: :text
    end
    f.actions
  end
end
