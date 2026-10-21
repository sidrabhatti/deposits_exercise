# A scheduled payment toward a tradeline. The sum of a tradeline's deposits
# may never exceed the tradeline's amount.
class Deposit < ApplicationRecord
  belongs_to :tradeline

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validate :deposit_date_is_a_date
  validate :amount_has_at_most_two_decimal_places
  validate :amount_within_outstanding_balance

  private

  # Unparseable dates (e.g. "2026-13-45") are cast to nil, so a plain presence
  # check would wrongly report them as blank.
  def deposit_date_is_a_date
    return if deposit_date.present?

    if deposit_date_before_type_cast.present?
      errors.add(:deposit_date, 'is not a valid date')
    else
      errors.add(:deposit_date, :blank)
    end
  end

  # The column has a scale of 2, so Rails would silently round 10.005 to 10.01.
  # Reject it instead of storing an amount the client didn't send.
  def amount_has_at_most_two_decimal_places
    raw = amount_before_type_cast.to_s.to_d
    errors.add(:amount, 'must have at most 2 decimal places') unless raw == raw.round(2)
  end

  def amount_within_outstanding_balance
    return if tradeline.nil? || amount.nil? || amount <= 0

    # Query the deposits rather than trusting a cached total, and exclude this
    # record so the check also holds if a deposit is ever updated.
    available = tradeline.amount.to_d - tradeline.deposits.where.not(id: id).sum(:amount)
    return if amount <= available

    errors.add(:amount, "exceeds the outstanding balance of #{format('%.2f', available)}")
  end
end
