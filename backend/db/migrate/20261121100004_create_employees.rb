class CreateEmployees < ActiveRecord::Migration[8.0]
  def change
    create_table :employees do |t|
      t.string :employee_code, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.date :hire_date, null: false
      t.string :status, null: false, default: "active"
      # No standalone country_id index: the (country_id, department_id) index covers it.
      t.references :country, null: false, foreign_key: true, index: false
      t.references :department, null: false, foreign_key: true
      t.references :job_title, null: false, foreign_key: true
      t.decimal :current_salary, precision: 15, scale: 2, null: false
      t.string :salary_currency, limit: 3, null: false
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :employees, :employee_code, unique: true
    add_index :employees, :email, unique: true
    add_index :employees, [ :country_id, :department_id ]

    add_check_constraint :employees, "status IN ('active', 'inactive')", name: "employees_status_check"
    add_check_constraint :employees, "current_salary > 0", name: "employees_current_salary_positive"
  end
end
