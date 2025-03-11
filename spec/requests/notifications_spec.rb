require 'rails_helper'

RSpec.describe "Notifications", type: :request do
  let(:merchant) { create(:merchant) }
  let!(:notification) { create(:notification, merchant: merchant) }

  describe "GET /notifications" do
    context 'with valid merchant' do
      it "returns http success" do
        get "/merchants/#{merchant.slug}/notifications"
        expect(response).to have_http_status(:success)
      end

      it 'lists merchants notifications' do
        get "/merchants/#{merchant.slug}/notifications"
        expect(response.body).to include(notification.title)
        expect(response.body).to include(notification.message)
      end
    end

    context 'with invalid merchant' do
      it "redirects to merchants page" do
        get "/merchants/invalid-slug/notifications"
        expect(response).to redirect_to(merchants_url)
      end
    end
  end
end
