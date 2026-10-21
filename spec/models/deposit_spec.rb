require 'rails_helper'

RSpec.describe Deposit, type: :model do
  let(:tradeline) { FactoryBot.create :tradeline, amount: 500 }

  it 'is valid with a date and an amount within the balance' do
    expect(FactoryBot.build(:deposit, tradeline: tradeline, amount: 500)).to be_valid
  end

  it 'requires a deposit date' do
    deposit = FactoryBot.build(:deposit, tradeline: tradeline, deposit_date: nil)

    expect(deposit).not_to be_valid
    expect(deposit.errors[:deposit_date]).to include("can't be blank")
  end

  it 'reports an unparseable date as invalid rather than blank' do
    deposit = FactoryBot.build(:deposit, tradeline: tradeline, deposit_date: '2026-13-45')

    expect(deposit).not_to be_valid
    expect(deposit.errors[:deposit_date]).to eq(['is not a valid date'])
  end

  it 'rejects amounts with more than 2 decimal places instead of rounding them' do
    deposit = FactoryBot.build(:deposit, tradeline: tradeline, amount: '10.005')

    expect(deposit).not_to be_valid
    expect(deposit.errors[:amount]).to include('must have at most 2 decimal places')
  end

  it 'requires a positive amount' do
    deposit = FactoryBot.build(:deposit, tradeline: tradeline, amount: 0)

    expect(deposit).not_to be_valid
    expect(deposit.errors[:amount]).to include('must be greater than 0')
  end

  it 'cannot exceed the outstanding balance' do
    FactoryBot.create :deposit, tradeline: tradeline, amount: 400
    deposit = FactoryBot.build(:deposit, tradeline: tradeline, amount: 100.01)

    expect(deposit).not_to be_valid
    expect(deposit.errors[:amount]).to include('exceeds the outstanding balance of 100.00')
  end

  it 'does not count itself against the balance when updated' do
    deposit = FactoryBot.create :deposit, tradeline: tradeline, amount: 500

    expect(deposit.update(amount: 450)).to be true
  end
end
