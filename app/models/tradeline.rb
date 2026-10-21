# An account on a credit report, such as a credit card or car loan. `amount`
# is the total owed; deposits pay it down.
class Tradeline < ApplicationRecord
  has_many :deposits, dependent: :destroy

  # Loads each tradeline's deposit total in the same query, so listing
  # tradelines doesn't issue one SUM query per row.
  scope :with_deposits_total, lambda {
    left_joins(:deposits)
      .select('tradelines.*, COALESCE(SUM(deposits.amount), 0) AS deposits_total')
      .group('tradelines.id')
  }

  # Uses the preloaded total from .with_deposits_total when present, otherwise
  # queries it. SQLite sums decimals as floats, hence the round(2).
  def deposits_total
    return self[:deposits_total].to_d.round(2) if has_attribute?(:deposits_total)

    deposits.sum(:amount)
  end

  # A tradeline with no amount is treated as having nothing owed.
  def outstanding_balance
    amount.to_d - deposits_total
  end

  # Whitelists the columns so the virtual deposits_total isn't serialized.
  def as_json(options = nil)
    super({ only: %i[id name amount created_at updated_at], methods: :outstanding_balance }.merge(options || {}))
  end
end
