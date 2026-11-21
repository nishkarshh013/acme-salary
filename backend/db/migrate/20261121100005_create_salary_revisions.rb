class CreateSalaryRevisions < ActiveRecord::Migration[8.0]
  def change
    # Append-only: rows are never updated, so there is no updated_at.
    create_table :salary_revisions do |t|
      # No standalone employee_id index: (employee_id, effective_date) covers it.
      t.references :employee, null: false, foreign_key: true, index: false
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.string :currency, limit: 3, null: false
      t.decimal :previous_amount, precision: 15, scale: 2
      t.date :effective_date, null: false
      t.string :reason, null: false
      t.datetime :created_at, null: false
    end

    add_index :salary_revisions, [ :employee_id, :effective_date ]
    add_check_constraint :salary_revisions, "amount > 0", name: "salary_revisions_amount_positive"
  end
end
