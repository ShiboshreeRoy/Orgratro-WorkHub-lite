class AnalyticsAggregationJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Generate daily analytics snapshot
    AnalyticsService.new.generate_daily_snapshot
    
    # Log the completion
    Rails.logger.info "Daily analytics snapshot generated at #{Time.current}"
    
    # Optionally generate weekly or monthly snapshots based on schedule
    generate_weekly_if_needed
    generate_monthly_if_needed
  end

  private

  def generate_weekly_if_needed
    # Only generate weekly snapshot on Sundays
    if Date.current.wday == 0  # Sunday
      AnalyticsService.new.generate_weekly_snapshot
      Rails.logger.info "Weekly analytics snapshot generated at #{Time.current}"
    end
  end

  def generate_monthly_if_needed
    # Only generate monthly snapshot on the first day of the month
    if Date.current.day == 1
      AnalyticsService.new.generate_monthly_snapshot
      Rails.logger.info "Monthly analytics snapshot generated at #{Time.current}"
    end
  end
end