class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [ :create ]

  def create
    # Check password confirmation manually
    if params[:user][:password] != params[:user][:password_confirmation]
      flash[:alert] = "
Password and confirmation did not match 😓"
      redirect_to new_user_registration_path and return
    end

    super do |resource|
      # Set user as standard role (buyer) by default
      resource.role = :standard
      # Send notification to admin about new user registration
      send_admin_notification(resource) if resource.persisted?
      apply_referral_if_present(resource)
    end
  end

  private

  def send_admin_notification(user)
    # Create a notification for admins about the new buyer registration
    Notification.create(
      title: "New Buyer Registration",
      message: "A new buyer has registered: #{user.email}. Please assign work.",
      notification_type: "admin_alert",
      priority: "high"
    )
  end

  def apply_referral_if_present(user)
    token = params[:ref] || params[:referral_token] || session.delete(:referral_token)
    return unless token.present?

    referral = Referral.find_by(token: token, claimed: false)
    return unless referral
    return if referral.referrer_id == user.id

    referral.mark_claimed!(user: user)
    user.update!(referred_by: referral.referrer)
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :role ])
  end
end
