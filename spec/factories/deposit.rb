# frozen_string_literal: true

FactoryBot.define do
  factory :deposit do
    tradeline
    deposit_date { 1.month.from_now.to_date }
    amount { 100.00 }
  end
end
