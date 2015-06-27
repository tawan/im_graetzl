class AddNotificationProfilesToUsers < ActiveRecord::Migration
  def change
    add_column :users, :website_notifications, :integer, :default => 0
  end
end
