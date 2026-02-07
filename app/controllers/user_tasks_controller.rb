class UserTasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_task, only: [ :edit, :update, :approve, :reject ]

  def index
    if current_user.admin?
      # Show all user tasks to admins, sorted by submission time
      @user_tasks = UserTask.includes(:user, :task).order(created_at: :desc).page(params[:page]).per(10)
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
    @user_task = UserTask.find(params[:id])
  end

  def user_task_params
    params.require(:user_task).permit(:proof, :image)
  end
end
