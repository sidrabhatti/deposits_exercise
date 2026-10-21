require 'rails_helper'

RSpec.describe 'Tradelines', type: :request do
  let!(:tradeline) { FactoryBot.create :tradeline, amount: 1000 }

  before { FactoryBot.create :deposit, tradeline: tradeline, amount: 250 }

  describe 'GET /tradelines' do
    it 'includes the outstanding balance of each tradeline' do
      get '/tradelines'

      body = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(body.size).to eq(1)
      expect(body.first['outstanding_balance'].to_d).to eq(BigDecimal('750'))
    end
  end

  describe 'GET /tradelines/:id' do
    it 'includes the outstanding balance' do
      get "/tradelines/#{tradeline.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['outstanding_balance'].to_d).to eq(BigDecimal('750'))
    end
  end
end
