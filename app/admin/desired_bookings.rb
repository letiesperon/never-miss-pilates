# frozen_string_literal: true

ActiveAdmin.register DesiredBooking do
  menu priority: 2
  permit_params :day_of_week, :hour, :enabled

  index do
    selectable_column
    id_column
    column :day_of_week
    column :hour
    column :enabled
    column :created_at
    actions
  end

  filter :day_of_week
  filter :hour
  filter :enabled

  show do
    attributes_table do
      row :id
      row :day_of_week
      row :hour
      tag_row :enabled
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :day_of_week
      f.input :hour
      f.input :enabled
    end
    f.actions
  end
end
