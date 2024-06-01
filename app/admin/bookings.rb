# frozen_string_literal: true

ActiveAdmin.register Booking do
  menu priority: 3
  permit_params :starts_at

  index do
    selectable_column
    id_column
    column :starts_at
    column :created_at
    actions
  end

  filter :starts_at

  show do
    attributes_table do
      row :id
      row :starts_at
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :starts_at, as: :datetime_picker
    end

    f.actions
  end
end
