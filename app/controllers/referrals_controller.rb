class ReferralsController < ApplicationController
    before_action :authenticate_user!


    def index
        @referrals = current_user.referrals_made.order(created_at: :desc)
    end


    def create
        invite_email = params[:invite_email].presence
        referral = current_user.create_referral_token!(invite_email: invite_email)


        ReferralMailer.with(referral: referral).invite_email.deliver_later if invite_email.present?


        render json: { referral_link: referral_link_for(referral) }, status: :created
    end


private


    def referral_link_for(referral)
# example: https://yourapp.com/users/sign_up?ref=TOKEN
        "#{root_url}users/sign_up?ref=#{referral.token}"
    end
end