# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_01_31_000942) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "crc_user_id"
    t.string "crc_token"
    t.string "crc_email"
    t.string "crc_password"
    t.string "phone_number"
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "bookings", force: :cascade do |t|
    t.datetime "starts_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "gym", default: "crc"
    t.bigint "admin_user_id", null: false
    t.index ["admin_user_id"], name: "index_bookings_on_admin_user_id"
    t.index ["starts_at"], name: "index_bookings_on_starts_at", unique: true
  end

  create_table "desired_bookings", force: :cascade do |t|
    t.string "day_of_week", null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "gym", default: "crc"
    t.bigint "admin_user_id", null: false
    t.integer "preferred_stations", array: true
    t.time "time", null: false
    t.index ["admin_user_id"], name: "index_desired_bookings_on_admin_user_id"
  end

  add_foreign_key "bookings", "admin_users"
  add_foreign_key "desired_bookings", "admin_users"
end
