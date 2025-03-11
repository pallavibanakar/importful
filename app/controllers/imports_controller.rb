class ImportsController < ApplicationController
  def create
    result = ImportAffiliate.call(merchant: @merchant, file: import_params[:file], delimiter: import_params[:delimiter])
    if result[:success]
      flash[:notice] = result[:message]
    else
      flash[:alert] = result[:message]
    end
    redirect_to new_merchant_import_path
  end

  def import_params
    params.permit(:file, :delimiter, :merchant_slug)
  end
end
