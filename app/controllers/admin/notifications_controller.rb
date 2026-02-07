class Admin::NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  def index
    @notifications = Notification.includes(:user)
                               .order(created_at: :desc)
                               .limit(20)
    @total_notifications = Notification.count
  end

  def create_global
    title = params[:title]
    message = params[:message]
    notification_type = params[:notification_type] || "announcement"
    priority = params[:priority] || "medium"
    expires_in = params[:expires_in]&.to_i&.hours

    if title.present? && message.present?
      Notification.create_global(title, message, type: notification_type.to_sym, priority: priority.to_sym, expires_in: expires_in)
      redirect_to admin_notifications_path, notice: "Global notification sent successfully."
    else
      redirect_to admin_notifications_path, alert: "Title and message are required."
    end
  end

  private

  def require_admin!
    redirect_to root_path, alert: "Access denied. Admin privileges required." unless current_user.admin?
  end
end
