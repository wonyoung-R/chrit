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

ActiveRecord::Schema[8.0].define(version: 2025_09_02_061052) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "knowledge_tags", force: :cascade do |t|
    t.bigint "knowledge_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["knowledge_id", "tag_id"], name: "index_knowledge_tags_on_knowledge_id_and_tag_id", unique: true
    t.index ["knowledge_id"], name: "index_knowledge_tags_on_knowledge_id"
    t.index ["tag_id"], name: "index_knowledge_tags_on_tag_id"
  end

  create_table "knowledges", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "original_url", null: false
    t.string "title"
    t.text "content"
    t.text "summary"
    t.string "content_type"
    t.string "status", default: "processing"
    t.string "thumbnail_url"
    t.integer "duration"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "keywords"
    t.datetime "published_at"
    t.text "error_message"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "input_tokens", default: 0
    t.integer "output_tokens", default: 0
    t.decimal "credits_consumed", precision: 5, scale: 2, default: "0.0"
    t.index ["content_type"], name: "index_knowledges_on_content_type"
    t.index ["created_at"], name: "index_knowledges_on_created_at"
    t.index ["credits_consumed"], name: "index_knowledges_on_credits_consumed"
    t.index ["original_url"], name: "index_knowledges_on_original_url"
    t.index ["status"], name: "index_knowledges_on_status"
    t.index ["user_id", "content_type"], name: "index_knowledges_on_user_id_and_content_type"
    t.index ["user_id", "created_at"], name: "index_knowledges_on_user_id_and_created_at"
    t.index ["user_id", "status"], name: "index_knowledges_on_user_id_and_status"
    t.index ["user_id"], name: "index_knowledges_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "plan_type", default: "free", null: false
    t.string "status", default: "pending", null: false
    t.string "payment_method"
    t.string "payment_id"
    t.decimal "amount", precision: 10, scale: 2
    t.datetime "started_at"
    t.datetime "expires_at"
    t.jsonb "payment_data", default: {}
    t.string "toss_order_id"
    t.string "toss_payment_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_subscriptions_on_expires_at"
    t.index ["plan_type"], name: "index_subscriptions_on_plan_type"
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["toss_order_id"], name: "index_subscriptions_on_toss_order_id", unique: true
    t.index ["toss_payment_key"], name: "index_subscriptions_on_toss_payment_key", unique: true
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.integer "count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["count"], name: "index_tags_on_count"
    t.index ["name"], name: "index_tags_on_name"
  end

  create_table "usage_trackings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "year", null: false
    t.integer "month", null: false
    t.integer "credits_used", default: 0
    t.integer "urls_processed", default: 0
    t.integer "youtube_count", default: 0
    t.integer "article_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "year", "month"], name: "index_usage_trackings_on_user_id_and_year_and_month", unique: true
    t.index ["user_id"], name: "index_usage_trackings_on_user_id"
    t.index ["year", "month"], name: "index_usage_trackings_on_year_and_month"
  end

  create_table "user_settings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.boolean "email_notifications", default: true
    t.string "privacy_mode", default: "private"
    t.string "language", default: "ko"
    t.string "timezone", default: "Asia/Seoul"
    t.integer "monthly_credit_limit", default: 10
    t.integer "used_credits", default: 0
    t.string "theme", default: "dark"
    t.boolean "email_verified", default: false
    t.datetime "email_verified_at"
    t.string "verification_token"
    t.datetime "last_credit_reset_at"
    t.jsonb "preferences", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "plan_type", default: "free", null: false
    t.index ["email_verified"], name: "index_user_settings_on_email_verified"
    t.index ["plan_type"], name: "index_user_settings_on_plan_type"
    t.index ["user_id"], name: "index_user_settings_on_user_id", unique: true
    t.index ["verification_token"], name: "index_user_settings_on_verification_token", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "knowledge_tags", "knowledges"
  add_foreign_key "knowledge_tags", "tags"
  add_foreign_key "knowledges", "users"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "usage_trackings", "users"
  add_foreign_key "user_settings", "users"
end
