class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :store_referral_token

  
  protected

  # Only allow admins
  def ensure_admin!
    redirect_to root_path, alert: "Access denied" unless current_user&.admin?
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :wp_number])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :wp_number])
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