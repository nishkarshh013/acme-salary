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

  normalizes :currency, :previous_currency, with: ->(value) { value.strip.upcase }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }
  validates :previous_amount, numericality: { greater_than: 0 }, allow_nil: true
  validates :previous_currency, format: { with: /\A[A-Z]{3}\z/ }, allow_nil: true
  validate :previous_amount_and_currency_together
  validates :effective_date, presence: true,
                             comparison: { less_than_or_equal_to: -> { Date.current },
                                           message: "can't be in the future" }
  validates :reason, presence: true

  private

  # Both are null on an employee's first revision; otherwise both are set.
  def previous_amount_and_currency_together
    if previous_amount.present? && previous_currency.blank?
      errors.add(:previous_currency, "must be present when there is a previous amount")
    elsif previous_amount.blank? && previous_currency.present?
      errors.add(:previous_amount, "must be present when there is a previous currency")
    end
  end
end
