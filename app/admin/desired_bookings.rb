# frozen_string_literal: true

ActiveAdmin.register DesiredBooking do
  menu priority: 2
  permit_params :admin_user_id, :gym, :day_of_week, :hour, :enabled, :preferred_stations

  includes :admin_user

  collection_action :trigger_crc_booker, method: :post do
    CRC::AllBooker::Worker.perform_async
    redirect_to collection_path, notice: 'Booker enqueued'
  end

  action_item :trigger_crc_booker, only: :index do
    link_to 'Run CRC Booker', trigger_crc_booker_admin_desired_bookings_path, method: :post
  end

  index do
    selectable_column
    id_column
    column :admin_user
    tag_column :gym
    column :day_of_week
    column :hour
    toggle_bool_column :enabled
    column :created_at
    actions
  end

  filter :admin_user, collection: proc { AdminUser.all }
  filter :gym, as: :select, collection: Gym::NAMES
  filter :day_of_week
  filter :hour
  filter :enabled

  show do
    attributes_table do
      row :id
      row :admin_user
      tag_row :gym
      row :day_of_week
      row :hour
      row :preferred_stations
      tag_row :enabled
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :admin_user, collection: AdminUser.all
      f.input :gym, collection: Gym::NAMES
      f.input :day_of_week
      f.input :hour
      f.input :preferred_stations,
              as: :text,
              hint: "Stations separated by space, comma or line break, in order of preference. eg: '11, 7'",
              input_html: {
                rows: 1,
                value: f.object.preferred_stations&.join(', ')
              }
      f.input :enabled
    end
    f.actions
  end
end
