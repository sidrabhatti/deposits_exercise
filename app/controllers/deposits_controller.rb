# Deposits are nested under a tradeline: /tradelines/:tradeline_id/deposits
class DepositsController < ApplicationController
  before_action :set_tradeline

  # GET /tradelines/:tradeline_id/deposits
  def index
    render json: @tradeline.deposits.order(:deposit_date, :id)
  end

  # GET /tradelines/:tradeline_id/deposits/:id
  def show
    render json: @tradeline.deposits.find(params[:id])
  end

  # POST /tradelines/:tradeline_id/deposits
  def create
    deposit = Deposit.new(deposit_params.merge(tradeline: @tradeline))

    # Lock the tradeline so two concurrent deposits can't both pass the
    # balance check and overdraw it together.
    saved = @tradeline.with_lock { deposit.save }

    if saved
      render json: deposit, status: :created
    else
      render json: { errors: deposit.errors }, status: :unprocessable_entity
    end
  end

  private

  # Scoping every lookup through the tradeline means a deposit can't be read
  # through a tradeline it doesn't belong to.
  def set_tradeline
    @tradeline = Tradeline.find(params[:tradeline_id])
  end

  def deposit_params
    params.require(:deposit).permit(:amount, :deposit_date)
  end
end
