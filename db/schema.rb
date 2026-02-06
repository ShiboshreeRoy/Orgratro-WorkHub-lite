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

ActiveRecord::Schema[7.2].define(version: 2026_02_03_140000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "achievements", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "badge_image"
    t.integer "points"
    t.string "achievement_type"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "affiliate_programs", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "commission_rate"
    t.text "terms"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "affiliate_relationships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "affiliate_program_id", null: false
    t.decimal "commission_amount"
    t.string "status"
    t.datetime "joined_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["affiliate_program_id"], name: "index_affiliate_relationships_on_affiliate_program_id"
    t.index ["joined_at"], name: "index_affiliate_relationships_on_joined_at"
    t.index ["status"], name: "index_affiliate_relationships_on_status"
    t.index ["user_id", "affiliate_program_id"], name: "idx_on_user_id_affiliate_program_id_fd1fe54b64", unique: true
    t.index ["user_id"], name: "index_affiliate_relationships_on_user_id"
  end

  create_table "analytics_snapshots", force: :cascade do |t|
    t.date "date"
    t.integer "total_users"
    t.integer "active_users_today"
    t.decimal "total_earnings"
    t.integer "pending_withdrawals"
    t.decimal "task_completion_rate"
    t.text "user_acquisition_trend"
    t.text "revenue_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "snapshot_type", default: "daily"
    t.index ["date", "snapshot_type"], name: "index_analytics_snapshots_on_date_and_snapshot_type", unique: true
    t.index ["date"], name: "index_analytics_snapshots_on_date"
  end

  create_table "asks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "url"
    t.string "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_asks_on_user_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "user_id"
    t.string "action", null: false
    t.string "resource_type", null: false
    t.integer "resource_id"
    t.text "changes"
    t.text "previous_values"
    t.text "ip_address"
    t.text "user_agent"
    t.text "session_id"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["resource_type", "resource_id"], name: "index_audit_logs_on_resource_type_and_resource_id"
    t.index ["user_id", "created_at"], name: "index_audit_logs_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "clicks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "link_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "learn_and_earn_id"
    t.index ["learn_and_earn_id"], name: "index_clicks_on_learn_and_earn_id"
    t.index ["link_id", "created_at"], name: "index_clicks_on_link_id_and_created_at"
    t.index ["link_id"], name: "index_clicks_on_link_id"
    t.index ["user_id", "created_at"], name: "index_clicks_on_user_id_and_created_at"
    t.index ["user_id", "link_id"], name: "index_clicks_on_user_id_and_link_id", unique: true
    t.index ["user_id"], name: "index_clicks_on_user_id"
  end

  create_table "contact_messages", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "subject"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_contact_messages_on_user_id"
  end

  create_table "email_campaigns", force: :cascade do |t|
    t.string "name"
    t.string "subject"
    t.text "content"
    t.string "sender_email"
    t.string "status"
    t.datetime "scheduled_at"
    t.datetime "sent_at"
    t.integer "recipients_count"
    t.integer "opened_count"
    t.integer "clicked_count"
    t.integer "bounce_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scheduled_at"], name: "index_email_campaigns_on_scheduled_at"
    t.index ["sent_at"], name: "index_email_campaigns_on_sent_at"
    t.index ["status"], name: "index_email_campaigns_on_status"
  end

  create_table "learn_and_earns", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "link"
    t.string "social_post"
    t.string "proof"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "link_id"
    t.index ["link_id"], name: "index_learn_and_earns_on_link_id"
    t.index ["user_id"], name: "index_learn_and_earns_on_user_id"
  end

  create_table "learn_and_earns_users", id: false, force: :cascade do |t|
    t.bigint "learn_and_earn_id", null: false
    t.bigint "user_id", null: false
  end

  create_table "links", force: :cascade do |t|
    t.string "title"
    t.string "url", null: false
    t.bigint "user_id", null: false
    t.integer "clicks_count", default: 0
    t.decimal "earnings", precision: 20, scale: 10, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "learn_and_earn_id"
    t.integer "total_clicks", default: 0, null: false
    t.index ["created_at"], name: "index_links_on_created_at"
    t.index ["learn_and_earn_id"], name: "index_links_on_learn_and_earn_id"
    t.index ["url"], name: "index_links_on_url", unique: true
    t.index ["user_id", "created_at"], name: "index_links_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_links_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "title"
    t.text "message"
    t.boolean "read"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "payment_gateways", force: :cascade do |t|
    t.string "name"
    t.string "api_key"
    t.string "secret_key"
    t.string "environment"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "promotional_codes", force: :cascade do |t|
    t.string "code"
    t.text "description"
    t.decimal "discount_percent"
    t.decimal "discount_fixed_amount"
    t.integer "usage_limit"
    t.integer "times_used"
    t.datetime "expires_at"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_promotional_codes_on_code", unique: true
    t.index ["expires_at"], name: "index_promotional_codes_on_expires_at"
    t.index ["is_active"], name: "index_promotional_codes_on_is_active"
  end

  create_table "referrals", force: :cascade do |t|
    t.bigint "referrer_id", null: false
    t.bigint "referred_user_id"
    t.string "token", null: false
    t.string "invite_email"
    t.decimal "reward_amount", precision: 16, scale: 8, default: "0.005", null: false
    t.boolean "claimed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "reward_processed", default: false
    t.decimal "processed_reward_amount", precision: 16, scale: 8
    t.index ["referred_user_id", "created_at"], name: "index_referrals_on_referred_user_id_and_created_at"
    t.index ["referred_user_id"], name: "index_referrals_on_referred_user_id"
    t.index ["referrer_id", "created_at"], name: "index_referrals_on_referrer_id_and_created_at"
    t.index ["referrer_id"], name: "index_referrals_on_referrer_id"
    t.index ["reward_processed"], name: "index_referrals_on_reward_processed"
    t.index ["token"], name: "index_referrals_on_token", unique: true
  end

  create_table "short_links", force: :cascade do |t|
    t.string "original"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_short_links_on_slug"
  end

  create_table "social_task_proofs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "post_url"
    t.integer "status"
    t.bigint "task_id"
    t.datetime "approved_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "admin_id"
    t.index ["admin_id"], name: "index_social_task_proofs_on_admin_id"
    t.index ["status", "created_at"], name: "index_social_task_proofs_on_status_and_created_at"
    t.index ["task_id"], name: "index_social_task_proofs_on_task_id"
    t.index ["user_id", "created_at"], name: "index_social_task_proofs_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_social_task_proofs_on_user_id"
  end

  create_table "social_tasks", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.string "image"
    t.text "description"
  end

  create_table "subscription_plans", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "price"
    t.text "features"
    t.integer "duration_days"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tasks", force: :cascade do |t|
    t.string "name"
    t.string "task_type"
    t.string "link"
    t.text "description"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "category"
    t.string "difficulty_level"
    t.decimal "reward_amount", precision: 16, scale: 8
    t.integer "quality_score"
    t.string "status", default: "pending"
    t.index ["category"], name: "index_tasks_on_category"
    t.index ["difficulty_level"], name: "index_tasks_on_difficulty_level"
    t.index ["status"], name: "index_tasks_on_status"
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "amount", precision: 16, scale: 8, null: false
    t.string "transaction_type", null: false
    t.text "description"
    t.decimal "balance_after", precision: 16, scale: 8
    t.string "reference_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["transaction_type"], name: "index_transactions_on_transaction_type"
    t.index ["user_id", "created_at"], name: "index_transactions_on_user_id_and_created_at"
    t.index ["user_id", "transaction_type"], name: "index_transactions_on_user_id_and_transaction_type"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "user_achievements", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "achievement_id", null: false
    t.datetime "earned_at"
    t.boolean "unlocked"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["achievement_id"], name: "index_user_achievements_on_achievement_id"
    t.index ["earned_at"], name: "index_user_achievements_on_earned_at"
    t.index ["unlocked"], name: "index_user_achievements_on_unlocked"
    t.index ["user_id", "achievement_id"], name: "index_user_achievements_on_user_id_and_achievement_id", unique: true
    t.index ["user_id"], name: "index_user_achievements_on_user_id"
  end

  create_table "user_activity_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "action"
    t.text "details"
    t.datetime "timestamp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_user_activity_logs_on_action"
    t.index ["timestamp"], name: "index_user_activity_logs_on_timestamp"
    t.index ["user_id", "action"], name: "index_user_activity_logs_on_user_id_and_action"
    t.index ["user_id"], name: "index_user_activity_logs_on_user_id"
  end

  create_table "user_links", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "link_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["link_id"], name: "index_user_links_on_link_id"
    t.index ["user_id"], name: "index_user_links_on_user_id"
  end

  create_table "user_promotional_codes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "promotional_code_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["promotional_code_id"], name: "index_user_promotional_codes_on_promotional_code_id"
    t.index ["user_id"], name: "index_user_promotional_codes_on_user_id"
  end

  create_table "user_tasks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "task_id", null: false
    t.text "proof"
    t.boolean "approved"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["task_id", "created_at"], name: "index_user_tasks_on_task_id_and_created_at"
    t.index ["task_id"], name: "index_user_tasks_on_task_id"
    t.index ["user_id", "created_at"], name: "index_user_tasks_on_user_id_and_created_at"
    t.index ["user_id", "task_id"], name: "index_user_tasks_on_user_id_and_task_id", unique: true
    t.index ["user_id"], name: "index_user_tasks_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role"
    t.decimal "balance", precision: 24, scale: 12, default: "0.0"
    t.boolean "suspended"
    t.string "name", default: "", null: false
    t.string "wp_number", default: "", null: false
    t.string "proof"
    t.string "referral_code", null: false
    t.string "referred_by"
    t.decimal "wallet_balance", precision: 10, scale: 6, default: "0.0"
    t.integer "total_referrals", default: 0
    t.decimal "referral_balance", precision: 16, scale: 8, default: "0.0", null: false
    t.bigint "referred_by_id"
    t.boolean "email_verified"
    t.string "email_verification_token"
    t.datetime "email_verification_sent_at"
    t.string "otp_secret"
    t.boolean "otp_required_for_login"
    t.text "otp_backup_codes"
    t.boolean "two_factor_enabled"
    t.datetime "last_active_at"
    t.integer "total_clicks"
    t.decimal "total_earnings"
    t.integer "tasks_completed"
    t.decimal "referral_conversion_rate"
    t.bigint "subscription_plan_id"
    t.datetime "subscription_start_date"
    t.datetime "subscription_end_date"
    t.boolean "is_subscribed", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["is_subscribed"], name: "index_users_on_is_subscribed"
    t.index ["referred_by_id"], name: "index_users_on_referred_by_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role", "created_at"], name: "index_users_on_role_and_created_at"
    t.index ["subscription_end_date"], name: "index_users_on_subscription_end_date"
    t.index ["subscription_plan_id"], name: "index_users_on_subscription_plan_id"
    t.index ["subscription_start_date"], name: "index_users_on_subscription_start_date"
    t.index ["suspended", "created_at"], name: "index_users_on_suspended_and_created_at"
  end

  create_table "withdrawals", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "amount"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "payment_method"
    t.string "transaction_id"
    t.datetime "processed_at"
    t.string "failure_reason"
    t.string "fraud_reason"
    t.string "crypto_address"
    t.text "payment_details"
    t.index ["status", "created_at"], name: "index_withdrawals_on_status_and_created_at"
    t.index ["user_id", "created_at"], name: "index_withdrawals_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_withdrawals_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "affiliate_relationships", "affiliate_programs"
  add_foreign_key "affiliate_relationships", "users"
  add_foreign_key "asks", "users"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "clicks", "learn_and_earns"
  add_foreign_key "clicks", "links"
  add_foreign_key "clicks", "users"
  add_foreign_key "contact_messages", "users"
  add_foreign_key "learn_and_earns", "links"
  add_foreign_key "learn_and_earns", "users"
  add_foreign_key "links", "learn_and_earns"
  add_foreign_key "links", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "referrals", "users", column: "referred_user_id"
  add_foreign_key "referrals", "users", column: "referrer_id"
  add_foreign_key "social_task_proofs", "users"
  add_foreign_key "tasks", "users"
  add_foreign_key "transactions", "users"
  add_foreign_key "user_achievements", "achievements"
  add_foreign_key "user_achievements", "users"
  add_foreign_key "user_activity_logs", "users"
  add_foreign_key "user_links", "links"
  add_foreign_key "user_links", "users"
  add_foreign_key "user_promotional_codes", "promotional_codes"
  add_foreign_key "user_promotional_codes", "users"
  add_foreign_key "user_tasks", "tasks"
  add_foreign_key "user_tasks", "users"
  add_foreign_key "users", "subscription_plans"
  add_foreign_key "users", "users", column: "referred_by_id"
  add_foreign_key "withdrawals", "users"
end
