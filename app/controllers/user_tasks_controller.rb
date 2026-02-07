class UserTasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_task, only: [ :edit, :update ]
  before_action :set_admin_user_task, only: [ :approve, :reject ]

  def index
    if request.path.include?("admin_user_tasks") && current_user.admin?
      # Show all user tasks to admins when accessed via admin routes
      @user_tasks = UserTask.includes(:user, :task).order(created_at: :desc).page(params[:page]).per(10)
    elsif params[:task_id]
      # Show user tasks for a specific task (nested resource)
      @task = Task.find(params[:task_id])
      @user_tasks = @task.user_tasks.where(user: current_user).includes(:task).page(params[:page]).per(10)
    else
      # Show only pending tasks to regular users
      @user_tasks = current_user.user_tasks.pending.includes(:task).order(created_at: :desc).page(params[:page]).per(10)
    end
  end

  def new
    @user_task = UserTask.new
  end

  def create
    # Automatically assign the logged-in user
    @user_task = UserTask.new(user_task_params.merge(user: current_user))
    if @user_task.save
      redirect_to user_tasks_path, notice: "Proof submitted successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to root_path, alert: "Access denied" unless @user_task.user == current_user
  end

  def update
    if @user_task.user == current_user && @user_task.update(user_task_params)
      redirect_to user_tasks_path, notice: "Proof submitted, waiting for approval."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def show
    # Check if this is an admin request
    if request.path.include?("admin_user_tasks") && current_user.admin?
      # Admin can see any user task
      @user_task = UserTask.find(params[:id])
    elsif params[:task_id]
      # For nested resource access
      @task = Task.find(params[:task_id])
      @user_task = @task.user_tasks.find(params[:id])
    else
      # Regular user accessing their own task
      @user_task = current_user.user_tasks.find(params[:id])
    end
  end

  def approve
    if current_user.admin?
      @user_task.update(approved: true)
      redirect_to user_tasks_path, notice: "Task approved!"
    else
      redirect_to root_path, alert: "Access denied"
    end
  end

  def reject
    if current_user.admin?
      @user_task.destroy
      redirect_to user_tasks_path, notice: "Task rejected and removed."
    else
      redirect_to root_path, alert: "Access denied"
    end
  end

  private

  def set_user_task
    if params[:task_id]
      @task = Task.find(params[:task_id])
      @user_task = @task.user_tasks.find(params[:id])
    else
      @user_task = UserTask.find(params[:id])
    end
  end

  def set_admin_user_task
    @user_task = UserTask.find(params[:id])
  end

  def user_task_params
    params.require(:user_task).permit(:proof, :image)
  end
end
