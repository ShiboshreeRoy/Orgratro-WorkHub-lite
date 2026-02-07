class InternDashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :check_intern_status

  def index
    @user = current_user

    # Fetch available tasks for intern - tasks table doesn't have is_active column
    @available_tasks = Task.limit(10)
    @user_tasks = current_user.user_tasks.includes(:task).order(created_at: :desc).limit(10)

    # Fetch click and earn links - links table doesn't have is_active column
    @available_links = Link.limit(10)
    @user_clicks = current_user.clicks.includes(:link).order(created_at: :desc).limit(5)

    # Fetch learn and earn courses - LearnAndEarn doesn't have is_active column
    @learn_courses = LearnAndEarn.where(status: "approved").limit(5)
    @user_courses = current_user.learn_and_earns.order(created_at: :desc).limit(5)

    # Calculate statistics
    @total_earned = current_user.balance || 0
    @tasks_completed = current_user.intern_tasks_completed
    @clicks_completed = current_user.clicks.count
    @courses_completed = current_user.learn_and_earns.where(status: "approved").count

    # Progress tracking
    @progress_percentage = current_user.intern_progress_percentage
    @required_tasks = current_user.required_tasks_for_graduation
    @current_level = current_user.intern_level
  end

  private

  def check_intern_status
    # Redirect graduated users to main dashboard
    if current_user.can_access_dashboard?
      redirect_to user_dashbord_index_path, notice: "Congratulations! You've graduated to the full dashboard!"
    end
  end
end
