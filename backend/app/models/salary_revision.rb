class SalaryRevision < ApplicationRecord
  # Append-only: once saved, a revision can't be updated or destroyed.
  # Corrections are recorded as a new revision.
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

  normalizes :currency, with: ->(value) { value.strip.upcase }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }
  validates :previous_amount, numericality: { greater_than: 0 }, allow_nil: true
  validates :effective_date, presence: true,
                             comparison: { less_than_or_equal_to: -> { Date.current },
                                           message: "can't be in the future" }
  validates :reason, presence: true
end
