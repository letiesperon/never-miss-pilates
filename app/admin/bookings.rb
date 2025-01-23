# frozen_string_literal: true

ActiveAdmin.register Booking do
  menu priority: 3

  includes :admin_user

  permit_params :admin_user_id, :gym, :starts_at

  index do
    selectable_column
    id_column
    column :admin_user
    tag_column :gym
    column :starts_at
    column :created_at
    actions
  end

  filter :admin_user, collection: proc { AdminUser.all }
  filter :gym, as: :select, collection: Gym::NAMES
  filter :starts_at

  show do
    attributes_table do
      row :id
      row :admin_user
      tag_row :gym
      row :starts_at
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :admin_user, collection: AdminUser.all
      f.input :gym, collection: Gym::NAMES
      f.input :starts_at, as: :datetime_picker
    end

    f.actions
  end
end
