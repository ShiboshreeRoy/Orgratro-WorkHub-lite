class SeedAdvancedFeatures < ActiveRecord::Migration[7.2]
  def up
    # Create default subscription plans
    puts "Creating default subscription plans..."
    SubscriptionPlan.create_default_plans
    
    # Create default achievements
    puts "Creating default achievements..."
    Achievement.create_default_achievements
    
    # Create default affiliate programs
    puts "Creating default affiliate programs..."
    AffiliateProgram.create_standard_program
    AffiliateProgram.create_premium_program
    
    # Create a default promotional code
    puts "Creating default promotional code..."
    PromotionalCode.create!(
      code: 'WELCOME10',
      description: 'Welcome bonus for new users',
      discount_percent: 10.0,
      usage_limit: 100,
      times_used: 0,
      expires_at: 30.days.from_now,
      is_active: true
    )
    
    # Generate first analytics snapshot (commented out due to dependency issues)
    # puts "Generating initial analytics snapshot..."
    # AnalyticsService.new.generate_daily_snapshot
    
    puts "Seed completed successfully!"
  end

  def down
    puts "Rollback not implemented for seeding data."
  end
end
