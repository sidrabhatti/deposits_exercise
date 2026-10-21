require 'rails_helper'

RSpec.describe Tradeline, type: :model do
  let(:tradeline) { FactoryBot.create :tradeline, amount: 1000 }

  describe '#outstanding_balance' do
    it 'equals the amount when there are no deposits' do
      expect(tradeline.outstanding_balance).to eq(BigDecimal('1000'))
    end

    it 'subtracts all deposits from the amount' do
      FactoryBot.create :deposit, tradeline: tradeline, amount: 100.25
      FactoryBot.create :deposit, tradeline: tradeline, amount: 200.50

      expect(tradeline.outstanding_balance).to eq(BigDecimal('699.25'))
    end

    it 'matches when loaded through .with_deposits_total' do
      FactoryBot.create :deposit, tradeline: tradeline, amount: 100.10
      FactoryBot.create :deposit, tradeline: tradeline, amount: 200.20
      other = FactoryBot.create :tradeline, amount: 50

      loaded = Tradeline.with_deposits_total.index_by(&:id)

      expect(loaded[tradeline.id].outstanding_balance).to eq(BigDecimal('699.70'))
      expect(loaded[other.id].outstanding_balance).to eq(BigDecimal('50'))
    end
  end
end
