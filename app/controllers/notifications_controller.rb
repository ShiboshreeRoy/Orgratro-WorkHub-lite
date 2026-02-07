class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    if request.format.json?
      # API endpoint for Stimulus controller
      user_id = params[:user_id] || current_user.id
      user = User.find_by(id: user_id) || current_user

      # Get both user-specific and global notifications
      user_notifications = user.notifications.active.recent.limit(10)
      global_notifications = Notification.global.active.recent.limit(10)

      # Combine and sort by creation time
      all_notifications = (user_notifications + global_notifications)
                        .sort_by { |n| n.created_at }
                        .reverse
                        .first(10)

      # Count unread notifications (both user-specific and global)
      user_unread = user.notifications.unread.active.count
      global_unread = Notification.global.unread.active.count
      unread_count = user_unread + global_unread

      render json: {
        notifications: all_notifications.as_json(only: [ :id, :title, :message, :read, :created_at, :priority, :notification_type ]),
        unread_count: unread_count
      }
    else
      # Regular HTML view
      @user_notifications = current_user.notifications.order(created_at: :desc)
      @global_notifications = Notification.global.order(created_at: :desc)
      @notifications = (@user_notifications + @global_notifications)
                         .sort_by { |n| n.created_at }
                         .reverse
    end
  end

  def show
    # Check if it's a user-specific notification
    @notification = current_user.notifications.find_by(id: params[:id])

    if @notification.nil?
      # Check if it's a global notification
      @notification = Notification.global.find_by(id: params[:id])
    end

    # If still nil, the notification doesn't exist
    if @notification.nil?
      redirect_to notifications_path, alert: "Notification not found."
      nil
    end
  end

  def mark_as_read
    # Check if it's a global notification or user-specific notification
    @notification = current_user.notifications.find_by(id: params[:id])

    if @notification.nil?
      # Check if it's a global notification that the user has seen
      @notification = Notification.global.find_by(id: params[:id])
      if @notification
        # For global notifications, we create a user-specific read record
        current_user.notifications.create(
          title: @notification.title,
          message: @notification.message,
          notification_type: @notification.notification_type,
          priority: @notification.priority,
          read: true,
          read_at: Time.current,
          expires_at: @notification.expires_at
        )
      else
        redirect_to notifications_path, alert: "Notification not found."
        return
      end
    else
      @notification.mark_as_read!
    end

    if request.format.json?
      render json: { success: true }
    else
      redirect_back(fallback_location: notifications_path)
    end
  end

  def destroy
    # Check if it's a user-specific notification
    @notification = current_user.notifications.find_by(id: params[:id])

    if @notification
      # It's a user-specific notification
      @notification.destroy
    else
      # It might be a global notification, we can't truly delete it
      # Instead, we can create a user-specific record to mark it as dismissed
      global_notification = Notification.global.find_by(id: params[:id])
      if global_notification
        current_user.notifications.create(
          title: global_notification.title,
          message: global_notification.message,
          notification_type: global_notification.notification_type,
          priority: global_notification.priority,
          read: true,
          read_at: Time.current,
          expires_at: global_notification.expires_at
        )
      else
        redirect_to notifications_path, alert: "Notification not found."
        return
      end
    end

    if request.format.json?
      render json: { success: true }
    else
      redirect_to notifications_path, notice: "Notification deleted successfully."
    end
  end
end
