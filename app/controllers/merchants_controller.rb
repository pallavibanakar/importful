class MerchantsController < ApplicationController
  skip_before_action :set_merchant, only: :index
  skip_before_action :redirect_unknown_merchants, only: :index

  def index
    @merchants = Merchant.all
  end
end
