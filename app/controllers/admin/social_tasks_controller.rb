module Admin
  class SocialTasksController < Admin::BaseController
    before_action :authenticate_admin!
    before_action :set_social_task, only: [:edit, :update, :destroy]

    def index
      @social_tasks = SocialTask.order(created_at: :desc)
    end

    def new
      @social_task = SocialTask.new
    end

    def create
      if params[:social_task][:file].present?
        import_from_file
      else
        @social_task = SocialTask.new(social_task_params)
        
        if @social_task.save
          redirect_to admin_social_tasks_path, notice: "Social campaign created successfully."
        else
          render :new, status: :unprocessable_entity
        end
      end
    end

    def edit
    end

    def update
      if @social_task.update(social_task_params)
        redirect_to admin_social_tasks_path, notice: "Social campaign updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @social_task.destroy
      redirect_to admin_social_tasks_path, notice: "Social campaign deleted successfully.", status: :see_other
    end

    def sample_template
      # Create a sample CSV template
      require 'csv'
      
      csv_content = CSV.generate do |csv|
        csv << ["Name", "URL", "Description", "Image"]
        csv << ["Summer Sale Campaign", "https://example.com/summer-sale", "Share our summer sale on your social media", "https://example.com/images/summer-sale.jpg"]
        csv << ["New Product Launch", "https://example.com/new-product", "Post about our new eco-friendly product launch", "https://example.com/images/new-product.jpg"]
        csv << ["Giveaway Contest", "https://example.com/giveaway", "Participate in our monthly giveaway contest", "https://example.com/images/giveaway.jpg"]
      end
      
      send_data csv_content, 
                filename: "social_tasks_template.csv", 
                type: "text/csv"
    end

    private

    def set_social_task
      @social_task = SocialTask.find(params[:id])
    end

    def social_task_params
      params.require(:social_task).permit(:name, :url, :description, :image, :file, :campaign_image)
    end

    def authenticate_admin!
      redirect_to root_path, alert: "Access denied." unless current_user&.admin?
    end

    def import_from_file
      file = params[:social_task][:file]
      created_count = 0
      failed_count = 0
      errors = []

      begin
        # Handle both Excel and CSV files
        if file.content_type == "text/csv"
          spreadsheet = Roo::CSV.new(file.path)
        else
          spreadsheet = Roo::Spreadsheet.open(file.path)
        end
        header = spreadsheet.row(1)
        
        # Map column indices
        name_col = header.index { |h| h.to_s.downcase.include?("name") } || 0
        url_col = header.index { |h| h.to_s.downcase.include?("url") } || 1
        desc_col = header.index { |h| h.to_s.downcase.include?("description") } || 2
        image_col = header.index { |h| h.to_s.downcase.include?("image") } || 3
        
        (2..spreadsheet.last_row).each do |i|
          row = spreadsheet.row(i)
          
          name = row[name_col]&.to_s&.strip
          url = row[url_col]&.to_s&.strip
          description = row[desc_col]&.to_s&.strip
          image = row[image_col]&.to_s&.strip
          
          next if name.blank? || url.blank? || description.blank?
          
          social_task = SocialTask.new(
            name: name,
            url: url,
            description: description,
            image: image.presence
          )
          
          if social_task.save
            created_count += 1
          else
            failed_count += 1
            errors << "Row #{i}: #{social_task.errors.full_messages.join(', ')}"
          end
        end
        
        if created_count > 0
          flash[:notice] = "Successfully imported #{created_count} social campaigns."
        end
        
        if failed_count > 0
          flash[:alert] = "Failed to import #{failed_count} campaigns: #{errors.join('; ')}"
        end
        
      rescue StandardError => e
        flash[:alert] = "Error importing file: #{e.message}"
      end
      
      redirect_to admin_social_tasks_path
    end
  end
end