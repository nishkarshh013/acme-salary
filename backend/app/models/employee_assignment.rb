class EmployeeAssignment < ApplicationRecord
  # Append-only: once saved, an assignment can't be updated or destroyed.
  # Corrections are recorded as a new assignment.
  #
  # readonly? blocks update, update_column and destroy; delete is overridden
  # because it skips the readonly check. Known trade-off: class-level
  # update_all, delete_all and raw SQL bypass both, and no database trigger
  # is used to stop them.
  def readonly? = persisted?

  def delete
    raise ActiveRecord::ReadOnlyRecord, "#{self.class.name} is append-only" if persisted?

    super
  end

  belongs_to :employee
  belongs_to :country
  belongs_to :department
  belongs_to :job_title

  validates :effective_date, presence: true,
                             comparison: { less_than_or_equal_to: -> { Date.current },
                                           message: "can't be in the future" }
  validates :reason, presence: true
end
