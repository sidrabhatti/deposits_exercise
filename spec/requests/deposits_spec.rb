require 'rails_helper'

RSpec.describe 'Deposits', type: :request do
  let(:tradeline) { FactoryBot.create :tradeline, amount: 1000 }

  describe 'GET /tradelines/:tradeline_id/deposits' do
    it "lists only that tradeline's deposits" do
      deposit = FactoryBot.create :deposit, tradeline: tradeline
      FactoryBot.create :deposit

      get "/tradelines/#{tradeline.id}/deposits"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.map { |d| d['id'] }).to eq([deposit.id])
    end

    it 'responds with a 404 for an unknown tradeline' do
      get '/tradelines/1000/deposits'

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /tradelines/:tradeline_id/deposits/:id' do
    let(:deposit) { FactoryBot.create :deposit, tradeline: tradeline, amount: 123.45 }

    it 'returns the deposit' do
      get "/tradelines/#{tradeline.id}/deposits/#{deposit.id}"

      body = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(body['id']).to eq(deposit.id)
      expect(body['amount'].to_d).to eq(BigDecimal('123.45'))
      expect(body['deposit_date']).to eq(deposit.deposit_date.iso8601)
    end

    it 'responds with a 404 for a deposit on another tradeline' do
      other = FactoryBot.create :deposit

      get "/tradelines/#{tradeline.id}/deposits/#{other.id}"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /tradelines/:tradeline_id/deposits' do
    let(:deposit_date) { 2.weeks.from_now.to_date.iso8601 }

    def create_deposit(params)
      post "/tradelines/#{tradeline.id}/deposits", params: params, as: :json
    end

    it 'creates a deposit and reduces the outstanding balance' do
      expect { create_deposit(deposit: { amount: 400, deposit_date: deposit_date }) }
        .to change(tradeline.deposits, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body['deposit_date']).to eq(deposit_date)
      expect(tradeline.reload.outstanding_balance).to eq(BigDecimal('600'))
    end

    it 'rejects a deposit that exceeds the outstanding balance' do
      FactoryBot.create :deposit, tradeline: tradeline, amount: 900

      expect { create_deposit(deposit: { amount: 100.01, deposit_date: deposit_date }) }
        .not_to change(Deposit, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['errors']['amount'])
        .to include('exceeds the outstanding balance of 100.00')
    end

    it 'returns validation errors for missing fields' do
      create_deposit(deposit: { amount: nil })

      errors = response.parsed_body['errors']
      expect(response).to have_http_status(:unprocessable_entity)
      expect(errors['amount']).to include("can't be blank")
      expect(errors['deposit_date']).to include("can't be blank")
    end

    it 'returns a validation error for an invalid date' do
      create_deposit(deposit: { amount: 10, deposit_date: 'not-a-date' })

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['errors']['deposit_date']).to eq(['is not a valid date'])
    end

    it 'responds with a 400 when the request body is empty' do
      create_deposit({})

      expect(response).to have_http_status(:bad_request)
    end

    it 'responds with a 404 for an unknown tradeline' do
      post '/tradelines/1000/deposits', params: { deposit: { amount: 1, deposit_date: deposit_date } }, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
