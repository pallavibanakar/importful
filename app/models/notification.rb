class Notification < ApplicationRecord
  belongs_to :merchant
  has_one_attached :errors_file

  validates :title, :message, presence: true

  scope :unread, -> { where(read_at: nil) }
end
