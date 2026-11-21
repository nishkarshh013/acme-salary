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

ActiveRecord::Schema[8.0].define(version: 2026_11_21_100004) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "countries", force: :cascade do |t|
    t.string "code", limit: 2, null: false
    t.string "name", null: false
    t.string "currency_code", limit: 3, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_countries_on_code", unique: true
  end

  create_table "departments", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_departments_on_lower_name", unique: true
  end

  create_table "employees", force: :cascade do |t|
    t.string "employee_code", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.date "hire_date", null: false
    t.string "status", default: "active", null: false
    t.bigint "country_id", null: false
    t.bigint "department_id", null: false
    t.bigint "job_title_id", null: false
    t.decimal "current_salary", precision: 15, scale: 2, null: false
    t.string "salary_currency", limit: 3, null: false
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id", "department_id"], name: "index_employees_on_country_id_and_department_id"
    t.index ["department_id"], name: "index_employees_on_department_id"
    t.index ["email"], name: "index_employees_on_email", unique: true
    t.index ["employee_code"], name: "index_employees_on_employee_code", unique: true
    t.index ["job_title_id"], name: "index_employees_on_job_title_id"
    t.check_constraint "current_salary > 0::numeric", name: "employees_current_salary_positive"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying, 'inactive'::character varying]::text[])", name: "employees_status_check"
  end

  create_table "job_titles", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_job_titles_on_lower_name", unique: true
  end

  add_foreign_key "employees", "countries"
  add_foreign_key "employees", "departments"
  add_foreign_key "employees", "job_titles"
end
