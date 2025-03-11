require 'rails_helper'

RSpec.describe Notification, type: :model do
  let(:merchant) { create(:merchant) }
  subject(:notification) { build(:notification, merchant: merchant) }

  describe '#merchant' do
    it { should belong_to(:merchant) }
  end

  describe '#title' do
    it { should validate_presence_of(:title) }
  end

  describe '#message' do
    it { should validate_presence_of(:message) }
  end

  describe ".unread" do
    let(:read_notification) { create(:notification, merchant: merchant, read_at: 1.day.ago) }
    let(:unread_notification) { create(:notification, merchant: merchant, read_at: nil) }

    it "returns only unread notifications" do
      unread_notifications = Notification.unread
      expect(unread_notifications).to include(unread_notification)
      expect(unread_notifications).to_not include(read_notification)
    end
  end
end
