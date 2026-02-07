class InternTaskCompletionsController < ApplicationController
  before_action :authenticate_user!

  def index
    @intern_task_completions = current_user.intern_task_completions.includes(:intern_task).order(created_at: :desc)
  end

  def new
    begin
      @intern_task = InternTask.find(params[:intern_task_id])
      @intern_task_completion = InternTaskCompletion.new
    rescue ActiveRecord::RecordNotFound => e
      redirect_to intern_dashboard_path, alert: "The requested intern task could not be found. Please try again."
    end
  end

  def create
    begin
      @intern_task = InternTask.find(params[:intern_task_id])
      @intern_task_completion = current_user.intern_task_completions.build(intern_task_completion_params.merge(intern_task: @intern_task))
      @intern_task_completion.status = "submitted"

      if @intern_task_completion.save
        redirect_to intern_dashboard_path, notice: "Task completion submitted successfully! Awaiting admin review."
      else
        render :new
      end
    rescue ActiveRecord::RecordNotFound => e
      redirect_to intern_dashboard_path, alert: "The requested intern task could not be found. Please try again."
    rescue => e
      redirect_to intern_dashboard_path, alert: "An error occurred: #{e.message}"
    end
  end

  private

  def intern_task_completion_params
    params.require(:intern_task_completion).permit(:proof, :proof_attachment, :intern_task_id)
  end

  def show
    @intern_task_completion = current_user.intern_task_completions.find(params[:id])
  end
end
