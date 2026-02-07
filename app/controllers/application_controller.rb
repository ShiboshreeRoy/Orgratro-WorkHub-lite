class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :store_referral_token

  def user_signed_in?
    !current_user.nil?
  end

  def current_user
    warden.user
  end

  def authenticate_user!(*args)
    redirect_to new_user_session_path unless user_signed_in?
  end

  def admin_user?
    current_user&.admin?
  end

  helper_method :admin_user?

  private

  def warden
    request.env["warden"]
  end

  # Redirect to appropriate dashboard after sign in
  def after_sign_in_path_for(resource)
    if resource.admin?
      admin_dashbord_index_path
    elsif resource.is_intern && !resource.can_access_dashboard?
      intern_dashboard_path
    else
      user_dashbord_index_path
    end
  end

  protected

  # Only allow admins
  def ensure_admin!
    redirect_to root_path, alert: "Access denied" unless current_user&.admin?
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :wp_number ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :wp_number ])
  end

  private

  def store_referral_token
    if params[:ref].present?
      session[:referral_token] = params[:ref]
    end
  end

  # Calculate earnings for a click, with consistent rates
  def calculate_click_earnings(link = nil)
    # Default earning rate - can be customized per link or campaign
    # Using a reasonable rate of $0.0003 per click
    0.0003
  end
end
