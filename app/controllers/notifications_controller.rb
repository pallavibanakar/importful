class NotificationsController < ApplicationController
  def index
    @notifications = @merchant.notifications.order(created_at: :desc)
    @notifications.where(read_at: nil).update_all(read_at: Time.current)
  end
end
