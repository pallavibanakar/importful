class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :merchant, null: false, foreign_key: true
      t.string :type
      t.string :message, null: false
      t.string :title, null: false
      t.timestamp :read_at

      t.timestamps
    end
  end
end
