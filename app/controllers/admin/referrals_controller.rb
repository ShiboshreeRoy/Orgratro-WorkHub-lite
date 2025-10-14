# app/controllers/admin/referrals_controller.rb
class Admin::ReferralsController < Admin::BaseController
  def index
    @referrals = Referral.includes(:referrer, :referred_user)
                         .order(created_at: :desc)
                         .page(params[:page])
                         .per(15)

    @total_referrals = Referral.count
  end
end
