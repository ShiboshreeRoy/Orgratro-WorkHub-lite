class PaymentController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!, except: [:process_user_payment]

  def dashboard
    @payment_gateways = PaymentGateway.all
    @subscription_plans = SubscriptionPlan.all
    @payment_processor = PaymentProcessorService.new
  end

  def payment_gateways
    @payment_gateways = PaymentGateway.page(params[:page]).per(20)
    @payment_gateway = PaymentGateway.new
  end

  def create_payment_gateway
    @payment_gateway = PaymentGateway.new(payment_gateway_params)

    if @payment_gateway.save
      redirect_to payment_gateways_path, notice: 'Payment gateway created successfully.'
    else
      @payment_gateways = PaymentGateway.page(params[:page]).per(20)
      render :payment_gateways
    end
  end

  def subscription_plans
    @subscription_plans = SubscriptionPlan.page(params[:page]).per(20)
    @subscription_plan = SubscriptionPlan.new
  end

  def create_subscription_plan
    @subscription_plan = SubscriptionPlan.new(subscription_plan_params)

    if @subscription_plan.save
      redirect_to subscription_plans_path, notice: 'Subscription plan created successfully.'
    else
      @subscription_plans = SubscriptionPlan.page(params[:page]).per(20)
      render :subscription_plans
    end
  end

  def process_user_payment
    # This method would be used by users to process their own payments
    @payment_processor = PaymentProcessorService.new
    @result = @payment_processor.process_payment(current_user, params[:amount], params[:gateway])
    
    if @result[:success]
      redirect_to profile_path, notice: 'Payment processed successfully.'
    else
      redirect_back(fallback_location: profile_path, alert: @result[:error])
    end
  end

  def payment_history
    @payments = current_user.transactions.where(transaction_type: ['payment', 'subscription']).page(params[:page]).per(20)
  end

  def subscription_management
    @user = current_user
    @subscription_plans = SubscriptionPlan.active
    @current_subscription = @user.subscription_plan
  end

  def subscribe_to_plan
    @user = current_user
    plan = SubscriptionPlan.find(params[:plan_id])

    @payment_processor = PaymentProcessorService.new
    result = @payment_processor.process_subscription_payment(@user, plan)

    if result[:success]
      @user.update!(
        subscription_plan: plan,
        subscription_start_date: Time.current,
        subscription_end_date: plan.duration_days.days.from_now,
        is_subscribed: true
      )
      
      redirect_to payment_subscription_management_path, notice: 'Successfully subscribed to the plan.'
    else
      redirect_back(fallback_location: payment_subscription_management_path, alert: result[:error])
    end
  end

  def cancel_subscription
    @user = current_user
    
    if @user.update(is_subscribed: false, subscription_end_date: Time.current)
      redirect_to payment_subscription_management_path, notice: 'Subscription cancelled successfully.'
    else
      redirect_back(fallback_location: payment_subscription_management_path, alert: 'Failed to cancel subscription.')
    end
  end

  private

  def payment_gateway_params
    params.require(:payment_gateway).permit(:name, :api_key, :secret_key, :environment, :is_active)
  end

  def subscription_plan_params
    params.require(:subscription_plan).permit(:name, :description, :price, :duration_days, :is_active, :features)
  end
end