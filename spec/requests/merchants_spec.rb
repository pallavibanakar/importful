require 'rails_helper'

RSpec.describe "Merchants", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/merchants"
      expect(response).to have_http_status(:success)
    end
  end
end
