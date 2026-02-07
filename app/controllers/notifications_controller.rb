class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    if request.format.json?
      # API endpoint for Stimulus controller
      user_id = params[:user_id] || current_user.id
      user = User.find_by(id: user_id) || current_user

      notifications = user.notifications
                        .active
                        .recent
                        .limit(10)

      unread_count = user.notifications.unread.active.count

      render json: {
        notifications: notifications.as_json(only: [ :id, :title, :message, :read, :created_at, :priority, :notification_type ]),
        unread_count: unread_count
      }
    else
      # Regular HTML view
      @notifications = current_user.notifications.order(created_at: :desc)
      @total_notifications = @notifications.count
    end
  end

  def show
    @notification = current_user.notifications.find(params[:id])
  end

  def mark_as_read
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read!

    if request.format.json?
      render json: { success: true }
    else
      redirect_back(fallback_location: notifications_path)
    end
  end

  def destroy
    @notification = current_user.notifications.find(params[:id])
    @notification.destroy

    if request.format.json?
      render json: { success: true }
    else
      redirect_to notifications_path, notice: "Notification deleted successfully."
    end
  end

  # Admin actions for creating global notifications
  def create_global
    unless current_user.admin?
      redirect_to root_path, alert: "Access denied."
      return
    end

    title = params[:title]
    message = params[:message]
    notification_type = params[:notification_type] || "announcement"
    priority = params[:priority] || "medium"
    expires_in = params[:expires_in]&.to_i&.hours

    if title.present? && message.present?
      Notification.create_global(title, message, type: notification_type.to_sym, priority: priority.to_sym, expires_in: expires_in)
      redirect_back(fallback_location: admin_dashbord_index_path, notice: "Global notification sent successfully.")
    else
      redirect_back(fallback_location: admin_dashbord_index_path, alert: "Title and message are required.")
    end
  end
end
