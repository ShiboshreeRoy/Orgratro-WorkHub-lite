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
    # Ensure we have a valid task
    unless @task
      redirect_to tasks_path, alert: "❌ Task not found."
      return
    end
    
    # Count users before sending
    user_count = User.count
    assigned_count = 0
    failed_count = 0
    
    begin
      User.find_each do |user|
        user_task = UserTask.find_or_create_by(user: user, task: @task)
        if user_task.persisted? || user_task.id.present?
          assigned_count += 1
        else
          failed_count += 1
          Rails.logger.error "Failed to assign task #{@task.id} to user #{user.id}: #{user_task.errors.full_messages.join(', ')}"
        end
      end
      
      if failed_count > 0
        redirect_to tasks_path, alert: "⚠️ Task sent to #{assigned_count} users, but #{failed_count} assignments failed."
      else
        redirect_to tasks_path, notice: "✅ Task successfully sent to all #{assigned_count} users!"
      end
      
    rescue StandardError => e
      Rails.logger.error "Error in send_to_all: #{e.message}"
      redirect_to tasks_path, alert: "❌ Failed to send task to users: #{e.message}"
    end
  end

  def sample_template
    # Create a sample CSV template using Roo
    require 'csv'
    
    # Generate CSV content
    csv_content = CSV.generate do |csv|
      # Add headers
      csv << ["Name", "Type", "Link", "Description"]
      
      # Add sample data
      csv << ["Sample Social Media Task", "Social", "https://facebook.com/example", "Like and share our post"]
      csv << ["Sample Website Visit", "URL", "https://example.com", "Visit our website and spend 2 minutes"]
      csv << ["Sample Survey Task", "Survey", "https://survey.example.com", "Complete our customer satisfaction survey"]
    end
    
    # Send the CSV file
    send_data csv_content, 
              filename: "tasks_template.csv", 
              type: "text/csv"
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
    created_tasks = []
    failed_tasks = []
    
    begin
      # Handle both Excel and CSV files
      if file.content_type == "text/csv"
        spreadsheet = Roo::CSV.new(file.path)
      else
        spreadsheet = Roo::Spreadsheet.open(file.path)
      end
      
      header = spreadsheet.row(1)
      
      # Map column headers to expected fields
      name_col = header.index { |h| h.to_s.downcase.include?("name") } || 0
      type_col = header.index { |h| h.to_s.downcase.include?("type") } || 1
      link_col = header.index { |h| h.to_s.downcase.include?("link") } || 2
      desc_col = header.index { |h| h.to_s.downcase.include?("description") } || 3
      
      (2..spreadsheet.last_row).each do |i|
        row = spreadsheet.row(i)
        link = row[link_col]&.to_s&.strip
        next if link.blank?
        
        task_name = row[name_col]&.to_s&.strip
        task_type = row[type_col]&.to_s&.strip
        description = row[desc_col]&.to_s&.strip
        
        # Use defaults if values are missing
        task_name = task_name.presence || "Imported Task #{i - 1}"
        task_type = task_type.presence || "URL"
        description = description.presence || "Imported from Excel/CSV file"
        
        task = Task.new(
          name: task_name,
          task_type: task_type,
          link: link,
          description: description,
          user: current_user
        )
        
        if task.save
          created_tasks << task
        else
          failed_tasks << { row: i, errors: task.errors.full_messages }
        end
      end
      
      # Set success message
      if created_tasks.any?
        flash[:notice] = "✅ Successfully imported #{created_tasks.count} task(s) from file."
      end
      
      # Set error message for failed imports
      if failed_tasks.any?
        error_details = failed_tasks.map { |f| "Row #{f[:row]}: #{f[:errors].join(', ')}" }.join("; ")
        flash[:alert] = "⚠️ Failed to import #{failed_tasks.count} task(s): #{error_details}"
      end
      
    rescue StandardError => e
      Rails.logger.error "Excel/CSV Import Error: #{e.message}"
      flash[:alert] = "⚠️ Failed to import tasks: #{e.message}"
    end
  end
end
