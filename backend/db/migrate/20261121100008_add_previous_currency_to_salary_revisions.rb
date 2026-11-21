class AddPreviousCurrencyToSalaryRevisions < ActiveRecord::Migration[8.0]
  # A country move changes the salary currency, so the previous amount needs
  # its own currency. Both are null on an employee's first revision.
  #
  # No backfill: history rows are never updated. If a database already holds
  # revisions with a previous_amount, adding the constraint fails and those
  # rows need a deliberate decision first.
  def change
    add_column :salary_revisions, :previous_currency, :string, limit: 3

    add_check_constraint :salary_revisions,
                         "(previous_amount IS NULL) = (previous_currency IS NULL)",
                         name: "salary_revisions_previous_amount_and_currency_together"
  end
end
