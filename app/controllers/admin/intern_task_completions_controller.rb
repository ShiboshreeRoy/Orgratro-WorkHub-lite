class Admin::InternTaskCompletionsController < Admin::BaseController
  before_action :set_intern_task_completion, only: [ :show, :update, :destroy, :submit ]

  def index
    @intern_task_completions = InternTaskCompletion.includes(:user, :intern_task).order(created_at: :desc)

    # Apply status filter if provided
    case params[:status]
    when "submitted"
      @filtered_completions = @intern_task_completions.submitted
    when "approved"
      @filtered_completions = @intern_task_completions.approved
    when "rejected"
      @filtered_completions = @intern_task_completions.rejected
    else
      @filtered_completions = @intern_task_completions
    end

    @pending_completions = @intern_task_completions.submitted
  end

  def show
  end

  def test_image
    @intern_task_completion = InternTaskCompletion.find(params[:id])
    render "admin/intern_task_completions/test_image"
  end

  def update
    if @intern_task_completion.update(intern_task_completion_params)
      redirect_to admin_intern_task_completions_path, notice: "Task completion updated successfully."
    else
      render :show
    end
  end

  # Admin approval/rejection of task completion
  def submit
    # Check if status is passed as URL parameter or request parameter
    status = params[:status] || params["status"]

    if [ "approved", "rejected", "needs_more_proof" ].include?(status)
      @intern_task_completion.update!(status: status)

      if status == "approved"
        # The after_save callback in the model will handle updating user progress
        redirect_to admin_intern_task_completions_path, notice: "Task completion approved successfully."
      elsif status == "needs_more_proof"
        redirect_to admin_intern_task_completions_path, notice: "Requested more proof from user. They can now resubmit."
      else
        redirect_to admin_intern_task_completions_path, notice: "Task completion rejected."
      end
    else
      redirect_to admin_intern_task_completions_path, alert: "Invalid status."
    end
  rescue => e
    redirect_to admin_intern_task_completions_path, alert: "Error updating task completion: #{e.message}"
  end

  private

  def set_intern_task_completion
    @intern_task_completion = InternTaskCompletion.find(params[:id])
  end

  def intern_task_completion_params
    params.require(:intern_task_completion).permit(:status, :proof_attachment)
  end
end
