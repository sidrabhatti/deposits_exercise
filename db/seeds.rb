# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Sample data for trying the API locally: `bin/rails db:seed`
card = Tradeline.find_or_create_by!(name: 'Visa Credit Card') { |t| t.amount = 3223.54 }
car = Tradeline.find_or_create_by!(name: 'Car Loan') { |t| t.amount = 15_000 }
Tradeline.find_or_create_by!(name: 'Personal Loan') { |t| t.amount = 5_000 }

if card.deposits.none?
  card.deposits.create!(deposit_date: 1.month.from_now.to_date, amount: 500)
  card.deposits.create!(deposit_date: 2.months.from_now.to_date, amount: 250.75)
end

car.deposits.create!(deposit_date: 1.month.from_now.to_date, amount: 1_200) if car.deposits.none?
