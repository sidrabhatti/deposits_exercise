class TradelinesController < ApplicationController
  # GET /tradelines
  def index
    render json: Tradeline.with_deposits_total.order(:id)
  end

  # GET /tradelines/:id
  def show
    render json: Tradeline.find(params[:id])
  end
end
