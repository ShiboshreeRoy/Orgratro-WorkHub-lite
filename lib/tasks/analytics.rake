namespace :analytics do
  desc "Generate daily analytics snapshot"
  task generate_daily_snapshot: :environment do
    puts "Generating daily analytics snapshot..."
    AnalyticsService.new.generate_daily_snapshot
    puts "Daily analytics snapshot generated successfully!"
  end

  desc "Run all analytics aggregations"
  task aggregate_all: :environment do
    puts "Running analytics aggregations..."
    AnalyticsAggregationJob.perform_now
    puts "Analytics aggregations completed!"
  end

  desc "Check and unlock user achievements"
  task check_achievements: :environment do
    puts "Checking user achievements..."
    
    User.find_each do |user|
      calculator = AchievementCalculatorService.new(user)
      unlocked = calculator.check_and_unlock_achievements
      puts "User #{user.email}: #{unlocked.count} achievements unlocked" if unlocked.any?
    end
    
    puts "Achievement check completed!"
  end
end