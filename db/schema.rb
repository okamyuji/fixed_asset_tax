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

ActiveRecord::Schema[8.1].define(version: 2025_12_29_062836) do
  create_table "asset_valuations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.decimal "assessed_value", precision: 15, scale: 2
    t.datetime "created_at", null: false
    t.bigint "fiscal_year_id", null: false
    t.bigint "municipality_id", null: false
    t.text "note"
    t.bigint "property_id", null: false
    t.string "source", default: "user", null: false
    t.json "special_measures_json"
    t.decimal "tax_base_value", precision: 15, scale: 2
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["fiscal_year_id"], name: "index_asset_valuations_on_fiscal_year_id"
    t.index ["municipality_id"], name: "index_asset_valuations_on_municipality_id"
    t.index ["property_id"], name: "index_asset_valuations_on_property_id"
    t.index ["tenant_id", "municipality_id", "fiscal_year_id", "property_id"], name: "idx_asset_valuations_uni", unique: true
    t.index ["tenant_id"], name: "index_asset_valuations_on_tenant_id"
  end

  create_table "calculation_results", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.json "breakdown_json"
    t.bigint "calculation_run_id", null: false
    t.datetime "created_at", null: false
    t.bigint "property_id", null: false
    t.decimal "tax_amount", precision: 15, scale: 2, default: "0.0", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["calculation_run_id"], name: "index_calculation_results_on_calculation_run_id"
    t.index ["property_id"], name: "index_calculation_results_on_property_id"
    t.index ["tenant_id", "calculation_run_id"], name: "index_calculation_results_on_tenant_id_and_calculation_run_id"
    t.index ["tenant_id", "property_id"], name: "index_calculation_results_on_tenant_id_and_property_id"
    t.index ["tenant_id"], name: "index_calculation_results_on_tenant_id"
  end

  create_table "calculation_runs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error_message"
    t.bigint "fiscal_year_id", null: false
    t.bigint "municipality_id", null: false
    t.json "parameters_json"
    t.string "status", default: "queued", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["fiscal_year_id"], name: "index_calculation_runs_on_fiscal_year_id"
    t.index ["municipality_id"], name: "index_calculation_runs_on_municipality_id"
    t.index ["tenant_id", "municipality_id", "fiscal_year_id"], name: "idx_on_tenant_id_municipality_id_fiscal_year_id_200a8c0d00"
    t.index ["tenant_id"], name: "index_calculation_runs_on_tenant_id"
  end

  create_table "depreciation_policies", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "fixed_asset_id", null: false
    t.string "method", default: "straight_line", null: false
    t.decimal "residual_rate", precision: 6, scale: 5, default: "0.0", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.integer "useful_life_years", null: false
    t.index ["fixed_asset_id"], name: "index_depreciation_policies_on_fixed_asset_id"
    t.index ["tenant_id", "fixed_asset_id"], name: "index_depreciation_policies_on_tenant_id_and_fixed_asset_id", unique: true
    t.index ["tenant_id"], name: "index_depreciation_policies_on_tenant_id"
  end

  create_table "depreciation_years", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.decimal "closing_book_value", precision: 15, scale: 2, null: false
    t.datetime "created_at", null: false
    t.decimal "depreciation_amount", precision: 15, scale: 2, null: false
    t.bigint "fiscal_year_id", null: false
    t.bigint "fixed_asset_id", null: false
    t.decimal "opening_book_value", precision: 15, scale: 2, null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["fiscal_year_id"], name: "index_depreciation_years_on_fiscal_year_id"
    t.index ["fixed_asset_id"], name: "index_depreciation_years_on_fixed_asset_id"
    t.index ["tenant_id", "fixed_asset_id", "fiscal_year_id"], name: "idx_depr_years_uni", unique: true
    t.index ["tenant_id"], name: "index_depreciation_years_on_tenant_id"
  end

  create_table "fiscal_years", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "ends_on", null: false
    t.date "starts_on", null: false
    t.datetime "updated_at", null: false
    t.integer "year", null: false
    t.index ["year"], name: "index_fiscal_years_on_year", unique: true
  end

  create_table "fixed_assets", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.date "acquired_on", null: false
    t.decimal "acquisition_cost", precision: 15, scale: 2, null: false
    t.string "asset_type", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "property_id", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_fixed_assets_on_property_id"
    t.index ["tenant_id", "acquired_on"], name: "index_fixed_assets_on_tenant_id_and_acquired_on"
    t.index ["tenant_id", "property_id"], name: "index_fixed_assets_on_tenant_id_and_property_id"
    t.index ["tenant_id"], name: "index_fixed_assets_on_tenant_id"
  end

  create_table "land_parcels", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.decimal "area_sqm", precision: 12, scale: 2
    t.datetime "created_at", null: false
    t.string "parcel_no"
    t.bigint "property_id", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_land_parcels_on_property_id"
    t.index ["tenant_id", "property_id"], name: "index_land_parcels_on_tenant_id_and_property_id"
    t.index ["tenant_id"], name: "index_land_parcels_on_tenant_id"
  end

  create_table "memberships", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "role", default: "admin", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["tenant_id", "user_id"], name: "index_memberships_on_tenant_id_and_user_id", unique: true
    t.index ["tenant_id"], name: "index_memberships_on_tenant_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "municipalities", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_municipalities_on_code", unique: true
  end

  create_table "parties", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.date "birth_date"
    t.string "corporate_number"
    t.datetime "created_at", null: false
    t.string "display_name", null: false
    t.bigint "tenant_id", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "corporate_number"], name: "index_parties_on_tenant_id_and_corporate_number", unique: true
    t.index ["tenant_id", "type"], name: "index_parties_on_tenant_id_and_type"
    t.index ["tenant_id"], name: "index_parties_on_tenant_id"
  end

  create_table "properties", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.bigint "municipality_id", null: false
    t.string "name", null: false
    t.bigint "party_id", null: false
    t.string "property_type"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["municipality_id"], name: "index_properties_on_municipality_id"
    t.index ["party_id"], name: "index_properties_on_party_id"
    t.index ["tenant_id", "municipality_id", "category"], name: "index_properties_on_tenant_id_and_municipality_id_and_category"
    t.index ["tenant_id", "party_id"], name: "index_properties_on_tenant_id_and_party_id"
    t.index ["tenant_id"], name: "index_properties_on_tenant_id"
  end

  create_table "tenants", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "plan", default: "free", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "asset_valuations", "fiscal_years"
  add_foreign_key "asset_valuations", "municipalities"
  add_foreign_key "asset_valuations", "properties"
  add_foreign_key "asset_valuations", "tenants"
  add_foreign_key "calculation_results", "calculation_runs"
  add_foreign_key "calculation_results", "properties"
  add_foreign_key "calculation_results", "tenants"
  add_foreign_key "calculation_runs", "fiscal_years"
  add_foreign_key "calculation_runs", "municipalities"
  add_foreign_key "calculation_runs", "tenants"
  add_foreign_key "depreciation_policies", "fixed_assets"
  add_foreign_key "depreciation_policies", "tenants"
  add_foreign_key "depreciation_years", "fiscal_years"
  add_foreign_key "depreciation_years", "fixed_assets"
  add_foreign_key "depreciation_years", "tenants"
  add_foreign_key "fixed_assets", "properties"
  add_foreign_key "fixed_assets", "tenants"
  add_foreign_key "land_parcels", "properties"
  add_foreign_key "land_parcels", "tenants"
  add_foreign_key "memberships", "tenants"
  add_foreign_key "memberships", "users"
  add_foreign_key "parties", "tenants"
  add_foreign_key "properties", "municipalities"
  add_foreign_key "properties", "parties"
  add_foreign_key "properties", "tenants"
end
