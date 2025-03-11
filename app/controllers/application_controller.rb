class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :set_merchant
  before_action :redirect_unknown_merchants

  private

  def set_merchant
    @merchant ||= Merchant.find_by(slug: params[:merchant_slug])
  end

  def redirect_unknown_merchants
    redirect_to merchants_path unless @merchant
  end
end
