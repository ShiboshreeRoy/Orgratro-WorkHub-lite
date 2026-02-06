class PaymentProcessorService
  def initialize(payment_gateway = nil)
    @payment_gateway = payment_gateway
  end

  # Process a payment transaction
  def process_payment(user, amount, currency = 'USD', options = {})
    validate_payment_params(user, amount, currency)

    # Select appropriate payment gateway if not provided
    gateway = @payment_gateway || select_active_gateway

    # Process the payment through the gateway
    gateway_response = gateway.process_payment(amount, currency, options)

    # Create transaction record
    transaction = create_transaction_record(
      user: user,
      amount: amount,
      currency: currency,
      gateway_response: gateway_response,
      transaction_type: 'payment',
      status: gateway_response[:success] ? 'completed' : 'failed'
    )

    # Handle successful payment
    if gateway_response[:success]
      handle_successful_payment(user, amount, transaction)
    else
      handle_failed_payment(user, amount, transaction, gateway_response[:gateway_response])
    end

    transaction
  end

  # Process a withdrawal payout
  def process_payout(user, amount, currency = 'USD', options = {})
    validate_payout_params(user, amount, currency)

    # Select appropriate payment gateway for payout
    gateway = @payment_gateway || select_active_gateway

    # For payouts, we might use different logic than regular payments
    # This simulates a payout transaction
    payout_response = {
      success: true,
      transaction_id: "payout_#{SecureRandom.hex(10)}",
      amount: amount,
      currency: currency,
      gateway_response: "Payout processed successfully",
      metadata: options
    }

    # Create transaction record
    transaction = create_transaction_record(
      user: user,
      amount: amount,
      currency: currency,
      gateway_response: payout_response,
      transaction_type: 'payout',
      status: payout_response[:success] ? 'completed' : 'failed'
    )

    # Handle successful payout
    if payout_response[:success]
      handle_successful_payout(user, amount, transaction)
    else
      handle_failed_payout(user, amount, transaction, payout_response[:gateway_response])
    end

    transaction
  end

  # Process a subscription payment
  def process_subscription_payment(user, plan, duration_months = 1)
    validate_subscription_params(user, plan, duration_months)

    # Calculate discounted price based on duration
    discounted_price = plan.discounted_price(duration_months)
    
    # Process the payment
    gateway = @payment_gateway || select_active_gateway
    gateway_response = gateway.process_payment(discounted_price, 'USD', {
      subscription_plan_id: plan.id,
      duration_months: duration_months,
      user_id: user.id
    })

    # Create transaction record
    transaction = create_transaction_record(
      user: user,
      amount: discounted_price,
      currency: 'USD',
      gateway_response: gateway_response,
      transaction_type: 'subscription',
      status: gateway_response[:success] ? 'completed' : 'failed'
    )

    # Handle successful subscription payment
    if gateway_response[:success]
      handle_successful_subscription_payment(user, plan, duration_months, transaction)
    else
      handle_failed_subscription_payment(user, plan, transaction, gateway_response[:gateway_response])
    end

    transaction
  end

  # Process a refund
  def process_refund(transaction_id, amount = nil, reason = nil)
    transaction = Transaction.find(transaction_id)
    gateway = transaction.payment_gateway || select_active_gateway

    refund_response = gateway.process_refund(
      transaction.gateway_transaction_id,
      amount,
      reason
    )

    # Create refund transaction record
    refund_transaction = create_transaction_record(
      user: transaction.user,
      amount: amount || transaction.amount,
      currency: transaction.currency,
      gateway_response: refund_response,
      transaction_type: 'refund',
      status: refund_response[:success] ? 'completed' : 'failed',
      parent_transaction_id: transaction.id
    )

    if refund_response[:success]
      handle_successful_refund(transaction, refund_transaction)
    else
      handle_failed_refund(transaction, refund_transaction, refund_response[:gateway_response])
    end

    refund_transaction
  end

  # Verify payment webhook
  def handle_webhook(gateway_name, payload, signature, timestamp = nil)
    gateway = PaymentGateway.find_by(name: gateway_name)
    return false unless gateway

    # Validate webhook signature
    return false unless gateway.validate_webhook_signature(payload, signature, timestamp)

    # Process the webhook based on event type
    process_webhook_event(gateway, payload)

    true
  end

  # Get user's payment history
  def user_payment_history(user, limit = 20)
    Transaction
      .where(user: user)
      .order(created_at: :desc)
      .limit(limit)
  end

  # Get user's payout history
  def user_payout_history(user, limit = 20)
    Transaction
      .where(user: user, transaction_type: 'payout')
      .order(created_at: :desc)
      .limit(limit)
  end

  # Get transaction by external ID
  def find_transaction_by_external_id(external_id)
    Transaction.find_by(gateway_transaction_id: external_id)
  end

  # Calculate fees for a transaction
  def calculate_fees(amount, gateway = nil)
    gateway ||= @payment_gateway || select_active_gateway
    
    # Default fee calculation (2.9% + $0.30 per transaction)
    # This would vary based on the actual payment gateway
    base_fee_percent = 2.9
    fixed_fee = 0.30
    
    percentage_fee = amount * (base_fee_percent / 100.0)
    total_fee = percentage_fee + fixed_fee
    
    {
      percentage_fee: percentage_fee,
      fixed_fee: fixed_fee,
      total_fee: total_fee,
      net_amount: amount - total_fee
    }
  end

  private

  def validate_payment_params(user, amount, currency)
    raise ArgumentError, "Invalid user" unless user.is_a?(User)
    raise ArgumentError, "Amount must be positive" unless amount && amount > 0
    raise ArgumentError, "Currency must be provided" unless currency.present?
  end

  def validate_payout_params(user, amount, currency)
    raise ArgumentError, "Invalid user" unless user.is_a?(User)
    raise ArgumentError, "Amount must be positive" unless amount && amount > 0
    raise ArgumentError, "Currency must be provided" unless currency.present?
  end

  def validate_subscription_params(user, plan, duration_months)
    raise ArgumentError, "Invalid user" unless user.is_a?(User)
    raise ArgumentError, "Invalid plan" unless plan.is_a?(SubscriptionPlan)
    raise ArgumentError, "Duration must be positive" unless duration_months && duration_months > 0
  end

  def select_active_gateway
    PaymentGateway.find_by(is_active: true) || 
    raise("No active payment gateway found")
  end

  def create_transaction_record(options)
    Transaction.create!(
      user: options[:user],
      amount: options[:amount],
      currency: options[:currency],
      gateway_transaction_id: options[:gateway_response][:transaction_id],
      gateway_response: options[:gateway_response],
      transaction_type: options[:transaction_type],
      status: options[:status],
      parent_transaction_id: options[:parent_transaction_id],
      payment_gateway: @payment_gateway
    )
  end

  def handle_successful_payment(user, amount, transaction)
    # Update user's account balance if applicable
    # This depends on the business logic
    Rails.logger.info "Successful payment of $#{amount} processed for user #{user.id}"
  end

  def handle_failed_payment(user, amount, transaction, error_message)
    Rails.logger.error "Failed payment of $#{amount} for user #{user.id}: #{error_message}"
  end

  def handle_successful_payout(user, amount, transaction)
    # Deduct from user's balance
    user.update(balance: user.balance - amount)
    
    # Log the payout
    Rails.logger.info "Successful payout of $#{amount} processed for user #{user.id}"
  end

  def handle_failed_payout(user, amount, transaction, error_message)
    Rails.logger.error "Failed payout of $#{amount} for user #{user.id}: #{error_message}"
  end

  def handle_successful_subscription_payment(user, plan, duration_months, transaction)
    # Activate the subscription for the user
    start_date = Date.current
    end_date = start_date + duration_months.months
    
    user.update(
      subscription_plan: plan,
      subscription_start_date: start_date,
      subscription_end_date: end_date,
      is_subscribed: true
    )
    
    Rails.logger.info "Successful subscription payment for #{user.email}, plan: #{plan.name}, duration: #{duration_months} months"
  end

  def handle_failed_subscription_payment(user, plan, transaction, error_message)
    Rails.logger.error "Failed subscription payment for #{user.email}, plan: #{plan.name}: #{error_message}"
  end

  def handle_successful_refund(original_transaction, refund_transaction)
    # Adjust balances if needed
    Rails.logger.info "Successful refund of $#{refund_transaction.amount} for transaction #{original_transaction.id}"
  end

  def handle_failed_refund(original_transaction, refund_transaction, error_message)
    Rails.logger.error "Failed refund for transaction #{original_transaction.id}: #{error_message}"
  end

  def process_webhook_event(gateway, payload)
    # Parse the webhook payload based on gateway
    event_type = extract_event_type(gateway.name, payload)
    
    case event_type
    when 'payment.success'
      handle_payment_success_webhook(payload)
    when 'payment.failed'
      handle_payment_failure_webhook(payload)
    when 'payout.completed'
      handle_payout_completed_webhook(payload)
    when 'refund.completed'
      handle_refund_completed_webhook(payload)
    else
      Rails.logger.info "Unhandled webhook event: #{event_type}"
    end
  end

  def extract_event_type(gateway_name, payload)
    # Extract event type based on the payment gateway
    case gateway_name
    when 'stripe'
      payload['type']
    when 'paypal'
      payload['event_type']
    when 'razorpay'
      payload['event']
    else
      payload['event'] || payload['type']
    end
  end

  def handle_payment_success_webhook(payload)
    # Handle successful payment webhook
    Rails.logger.info "Payment success webhook received: #{payload}"
  end

  def handle_payment_failure_webhook(payload)
    # Handle failed payment webhook
    Rails.logger.info "Payment failure webhook received: #{payload}"
  end

  def handle_payout_completed_webhook(payload)
    # Handle payout completed webhook
    Rails.logger.info "Payout completed webhook received: #{payload}"
  end

  def handle_refund_completed_webhook(payload)
    # Handle refund completed webhook
    Rails.logger.info "Refund completed webhook received: #{payload}"
  end
end