class Admin::InternTasksController < Admin::BaseController
  before_action :set_intern_task, only: [ :show, :edit, :update, :destroy ]

  def index
    @intern_tasks = InternTask.includes(:admin).order(created_at: :desc)
  end

  def show
    @submissions = @intern_task.intern_task_completions.includes(:user).order(created_at: :desc)
  end

  def new
    @intern_task = InternTask.new
  end

  def create
    @intern_task = InternTask.new(intern_task_params)
    @intern_task.admin = current_user

    if @intern_task.save
      redirect_to admin_intern_tasks_path, notice: "Intern task was successfully created."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @intern_task.update(intern_task_params)
      redirect_to admin_intern_tasks_path, notice: "Intern task was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @intern_task.destroy
    redirect_to admin_intern_tasks_path, notice: "Intern task was successfully deleted."
  end

  private

  def set_intern_task
    @intern_task = InternTask.find(params[:id])
  end

  def intern_task_params
    params.require(:intern_task).permit(:title, :description, :task_type, :video_url, :status, :priority, :video_file)
  end
end
