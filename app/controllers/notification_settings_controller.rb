class NotificationSettingsController < ApplicationController
  before_filter :authenticate_user!

  def index

  end

  def toggle_website_notification
    type = params[:type].to_sym
    unless Notification::TYPE_BITMASKS.keys.include?(type)
      render body: "unrecognized type: #{type} in order to toggle website_notification", status: :forbidden
      return
    end
    current_user.toggle_website_notification(type)

    render nothing: true
  end

  def mark_as_seen
    Notification.where(user_id: current_user.id).update_all(seen: true)
    render nothing: true
  end
end
