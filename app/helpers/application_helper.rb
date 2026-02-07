module ApplicationHelper
    def user_signed_in?
        !current_user.nil?
    end

    def current_user
        controller.current_user if controller.respond_to?(:current_user)
    end

    def referral_link_for(referral)
        "#{root_url}users/sign_up?ref=#{referral.token}"
    end
end
