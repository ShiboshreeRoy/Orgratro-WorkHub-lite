module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!

    def authenticate_user!
      redirect_to new_user_session_url unless user_signed_in?
    end

    private

    def require_admin!
      unless current_user && current_user.admin?
        flash[:alert] = "You are not authorized to access this section."
        redirect_to root_path
      end
    end
  end
end
