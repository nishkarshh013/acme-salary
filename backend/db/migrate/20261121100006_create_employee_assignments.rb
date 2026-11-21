class CreateEmployeeAssignments < ActiveRecord::Migration[8.0]
  def change
    # Append-only: rows are never updated, so there is no updated_at.
    create_table :employee_assignments do |t|
      # No standalone employee_id index: (employee_id, effective_date) covers it.
      t.references :employee, null: false, foreign_key: true, index: false
      t.references :country, null: false, foreign_key: true
      t.references :department, null: false, foreign_key: true
      t.references :job_title, null: false, foreign_key: true
      t.date :effective_date, null: false
      t.string :reason, null: false
      t.datetime :created_at, null: false
    end

    add_index :employee_assignments, [ :employee_id, :effective_date ]
  end
end
