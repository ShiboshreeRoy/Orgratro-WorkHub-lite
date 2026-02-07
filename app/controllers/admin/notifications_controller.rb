class Admin::NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  def index
    @notifications = Notification.includes(:user)
                               .order(created_at: :desc)
                               .limit(20)
    @total_notifications = Notification.count
  end

  private

  def require_admin!
    redirect_to root_path, alert: "Access denied. Admin privileges required." unless current_user.admin?
  end
end
