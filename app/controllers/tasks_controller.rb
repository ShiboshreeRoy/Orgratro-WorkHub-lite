class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_task, only: [:show, :edit, :update, :destroy, :send_to_all]

  # 🔒 Only admins can create, update, delete, or send tasks
  before_action :require_admin!, except: [:index, :show]

  def index
  # Normal users: see only visible tasks
  # Admins: see everything
  @tasks = Task.order(created_at: :desc)
               .page(params[:page])
               .per(10)  # Adjust the number of tasks per page
end


  def show
  end

  def new
    @task = Task.new
  end

  def create
    if params[:task][:file].present?
      import_tasks_from_file(params[:task][:file])
      redirect_to tasks_path, notice: "📂 Tasks imported successfully from Excel."
    else
      @task = Task.new(task_params.merge(user: current_user))
      if @task.save
        redirect_to tasks_path, notice: "✅ Task created successfully."
      else
        flash.now[:alert] = "❌ Failed to create task."
        render :new, status: :unprocessable_entity
      end
    end
  end

  def edit
  end

  def update
    if @task.update(task_params)
      redirect_to tasks_path, notice: "✅ Task updated successfully."
    else
      flash.now[:alert] = "❌ Failed to update task."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy
    redirect_to tasks_path, notice: "🗑️ Task deleted successfully."
  end

  def send_to_all
    User.find_each do |user|
      UserTask.find_or_create_by(user: user, task: @task)
    end
    redirect_to tasks_path, notice: "📢 Task sent to all users!"
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:name, :task_type, :link, :description, :image)
  end

  def require_admin!
    return if current_user.admin?
    redirect_to tasks_path, alert: "⛔ Access denied. Only admins can perform this action."
  end

  def import_tasks_from_file(file)
    spreadsheet = Roo::Spreadsheet.open(file.path)
    header = spreadsheet.row(1)

    (2..spreadsheet.last_row).each do |i|
      row = spreadsheet.row(i)
      link = row[0]
      next if link.blank?

      Task.create!(
        name: "Imported Task #{i - 1}",
        task_type: "URL",
        link: link,
        description: "Imported from Excel file",
        user: current_user
      )
    end
  rescue StandardError => e
    Rails.logger.error "Excel Import Error: #{e.message}"
    flash[:alert] = "⚠️ Failed to import some tasks: #{e.message}"
  end
end
