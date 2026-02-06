class MarketingController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!

  def dashboard
    @marketing_service = MarketingAnalyticsService.new
    @marketing_analytics = @marketing_service.marketing_dashboard_analytics
  end

  def promotional_codes
    @promotional_codes = PromotionalCode.includes(:user_promotional_codes).page(params[:page]).per(20)
    @promotional_code = PromotionalCode.new
  end

  def create_promotional_code
    @promotional_code = PromotionalCode.new(promotional_code_params)

    if @promotional_code.save
      redirect_to marketing_promotional_codes_path, notice: 'Promotional code created successfully.'
    else
      @promotional_codes = PromotionalCode.page(params[:page]).per(20)
      render :promotional_codes
    end
  end

  def achievements
    @achievements = Achievement.includes(:user_achievements).page(params[:page]).per(20)
    @achievement = Achievement.new
  end

  def create_achievement
    @achievement = Achievement.new(achievement_params)

    if @achievement.save
      redirect_to marketing_achievements_path, notice: 'Achievement created successfully.'
    else
      @achievements = Achievement.page(params[:page]).per(20)
      render :achievements
    end
  end

  def email_campaigns
    @email_campaigns = EmailCampaign.page(params[:page]).per(20)
    @email_campaign = EmailCampaign.new
  end

  def create_email_campaign
    @email_campaign = EmailCampaign.new(email_campaign_params)

    if @email_campaign.save
      redirect_to marketing_email_campaigns_path, notice: 'Email campaign created successfully.'
    else
      @email_campaigns = EmailCampaign.page(params[:page]).per(20)
      render :email_campaigns
    end
  end

  def affiliate_programs
    @affiliate_programs = AffiliateProgram.includes(:affiliate_relationships).page(params[:page]).per(20)
    @affiliate_program = AffiliateProgram.new
  end

  def create_affiliate_program
    @affiliate_program = AffiliateProgram.new(affiliate_program_params)

    if @affiliate_program.save
      redirect_to marketing_affiliate_programs_path, notice: 'Affiliate program created successfully.'
    else
      @affiliate_programs = AffiliateProgram.page(params[:page]).per(20)
      render :affiliate_programs
    end
  end

  def marketing_reports
    @marketing_service = MarketingAnalyticsService.new
    @report_type = params[:report_type] || 'comprehensive'
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : 30.days.ago.to_date
    @end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.current
    
    @marketing_report = @marketing_service.generate_marketing_report(@report_type, {
      start_date: @start_date,
      end_date: @end_date
    })
  end

  private

  def promotional_code_params
    params.require(:promotional_code).permit(:code, :description, :discount_percent, :discount_fixed_amount, 
                                           :usage_limit, :expires_at, :is_active)
  end

  def achievement_params
    params.require(:achievement).permit(:name, :description, :badge_image, :points, :achievement_type, :is_active)
  end

  def email_campaign_params
    params.require(:email_campaign).permit(:name, :subject, :content, :sender_email, :status, :scheduled_at)
  end

  def affiliate_program_params
    params.require(:affiliate_program).permit(:name, :description, :commission_rate, :terms, :is_active)
  end
end