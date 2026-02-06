namespace :demo do
  desc "Create demo data for showcasing new features"
  task create_demo_data: :environment do
    puts "Creating demo data for advanced features..."

    # Create some demo users if they don't exist
    unless User.find_by(email: 'demo-admin@example.com')
      admin_user = User.create!(
        email: 'demo-admin@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        role: 'admin',
        name: 'Demo Admin',
        referral_code: 'DEMO_ADMIN'
      )
      puts "Created admin user: #{admin_user.email}"
    end

    unless User.find_by(email: 'demo-user@example.com')
      demo_user = User.create!(
        email: 'demo-user@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        role: 'standard',
        name: 'Demo User',
        referral_code: 'DEMO_USER',
        balance: 50.0,
        referral_balance: 25.0
      )
      puts "Created demo user: #{demo_user.email}"
    end

    # Create some demo achievements if they don't exist
    achievement_names = ['First Steps', 'Social Butterfly', 'Quick Learner', 'Consistent Contributor']
    achievement_names.each do |name|
      unless Achievement.find_by(name: name)
        Achievement.create!(
          name: name,
          description: "Demo achievement for #{name}",
          points: 10,
          achievement_type: 'task_completion',
          is_active: true
        )
        puts "Created achievement: #{name}"
      end
    end

    # Create some demo promotional codes
    unless PromotionalCode.find_by(code: 'DEMO20')
      promo = PromotionalCode.create!(
        code: 'DEMO20',
        description: 'Demo promotional code',
        discount_percent: 20.0,
        usage_limit: 100,
        times_used: 0,
        expires_at: 30.days.from_now,
        is_active: true
      )
      puts "Created promotional code: #{promo.code}"
    end

    # Create some demo affiliate programs
    unless AffiliateProgram.find_by(name: 'Demo Affiliate Program')
      affiliate_program = AffiliateProgram.create!(
        name: 'Demo Affiliate Program',
        description: 'Demo affiliate program for testing',
        commission_rate: 12.5,
        terms: 'Demo terms and conditions',
        is_active: true
      )
      puts "Created affiliate program: #{affiliate_program.name}"
    end

    puts "Demo data creation completed!"
    puts "\nAdmin panel: http://localhost:3000/admin"
    puts "Demo login: demo-admin@example.com / password123"
    puts "Analytics dashboard: http://localhost:3000/analytics/dashboard"
  end
end