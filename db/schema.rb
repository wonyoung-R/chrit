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

ActiveRecord::Schema[8.0].define(version: 2025_09_01_074602) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "knowledge_tags", force: :cascade do |t|
    t.bigint "knowledge_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["status"], name: "index_knowledges_on_status"
    t.index ["user_id", "created_at"], name: "index_knowledges_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_knowledges_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.integer "count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["count"], name: "index_tags_on_count"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "knowledge_tags", "knowledges"
  add_foreign_key "knowledge_tags", "tags"
  add_foreign_key "knowledges", "users"
end
