# frozen_string_literal: true

ActiveAdmin.register AdminUser do
  menu priority: 1

  permit_params :email, :password, :password_confirmation, :crc_user_id, :crc_token, :crc_email,
                :crc_password

  member_action :authenticate_crc, method: :post do
    admin_user = AdminUser.find(params[:id])

    authenticator = CRC::Authenticator.new(admin_user: admin_user)
    authenticator.authenticate

    if authenticator.success?
      flash[:notice] = 'CRC Authentication succeeded.'
    else
      flash[:error] =
        "CRC Authentication failed: #{authenticator.errors.full_messages}"
    end

    redirect_to resource_path(admin_user)
  end

  action_item :authenticate_crc, only: %i[show edit] do
    link_to('Refresh CRC Token',
            authenticate_crc_admin_admin_user_path(resource),
            method: :post)
  end

  controller do
    def update_resource(object, attributes)
      update_method = attributes.first[:password].present? ? :update : :update_without_password
      object.send(update_method, *attributes)
    end
  end

  index do
    selectable_column
    id_column
    column :email
    column :current_sign_in_at
    column :sign_in_count
    column :created_at
    actions
  end

  filter :email

  show do
    columns do
      column do
        attributes_table title: 'General' do
          row :id
          row :email
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

      column do
        attributes_table title: 'CRC' do
          row :crc_email
          row :crc_password
          row :crc_user_id
          row :crc_token
        end
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :email
      f.input :crc_email
      f.input :crc_password, as: :string
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end
end
