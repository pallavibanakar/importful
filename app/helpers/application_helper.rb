module ApplicationHelper
  def unread_notifications_count(merchant)
    return 0 unless merchant
    merchant.notifications.unread.count
  end

  def merchant_name(slug)
    return "unknown" unless slug
    slug.split("-").map(&:capitalize).join(" ")
  end
end
