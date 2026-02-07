class LearnAndEarnsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_learn_and_earn, only: %i[show edit update destroy track_click]
  before_action :authorize_admin!, only: %i[new create bulk_create]
  before_action :authorize_user_or_admin!, only: %i[edit update destroy]

  def index
    if current_user.admin?
      # For admins: show only pending and rejected entries (hide approved)
      @learn_and_earns = LearnAndEarn.includes(:user)
                                    .where.not(status: "approved")
                                    .order(created_at: :desc)
                                    .page(params[:page])
                                    .per(10)
      @users = User.all
      @available_tasks = Task.active.limit(5)
      @available_links = Link.active.limit(5)
    else
      # For regular users: show their own entries
      @learn_and_earns = current_user.learn_and_earns
                                    .order(created_at: :desc)
                                    .page(params[:page])
                                    .per(10)
      @available_tasks = Task.active.limit(5)
      @available_links = Link.active.limit(5)
      @user_stats = {
        total_earned: current_user.balance || 0,
        tasks_completed: current_user.user_tasks.where(approved: true).count,
        clicks_made: current_user.clicks.count
      }
    end
  end

  def track_click
    @learn_and_earn.clicks.create!(user: current_user) # if you want to track user who clicked
    redirect_to @learn_and_earn.link
  end

  def show
  end

  def new
    @learn_and_earn = LearnAndEarn.new
  end

  def create
    if params[:learn_and_earn][:file].present?
      # Handle Excel/CSV file upload
      process_bulk_import
    else
      # Handle single entry creation
      @learn_and_earn = LearnAndEarn.new(learn_and_earn_params)
      @learn_and_earn.skip_proof_validation = true  # allow admin to skip proof validation

      respond_to do |format|
        if @learn_and_earn.save
          # Automatically send to all users if it's a single entry (not bulk upload)
          if !params[:learn_and_earn][:file].present?
            created_count = distribute_to_all_users(@learn_and_earn)
            format.html { redirect_to learn_and_earns_path, notice: "Learn & Earn entry successfully created and distributed to #{created_count} users." }
          else
            format.html { redirect_to learn_and_earns_path, notice: "Learn & Earn entry successfully created." }
          end
          format.json { render :show, status: :created, location: @learn_and_earn }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @learn_and_earn.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def bulk_create
    # Create a template entry first
    template_entry = LearnAndEarn.new(
      link: "https://example.com/default-link",
      social_post: "Default social media post for earning rewards",
      status: "pending",
      user: current_user
    )
    template_entry.skip_proof_validation = true

    if template_entry.save
      # Distribute to all users
      created_count = distribute_to_all_users(template_entry)
      redirect_to learn_and_earns_path, notice: "Successfully created #{created_count} Learn & Earn entries for all users."
    else
      redirect_to new_learn_and_earn_path, alert: "Failed to create template entry: #{template_entry.errors.full_messages.join(', ')}"
    end
  end

  def bulk_delete
    # Authorization check - only admins can bulk delete
    unless current_user.admin?
      respond_to do |format|
        format.html { redirect_to root_path, alert: "Access denied. Only administrators can perform bulk operations.", status: :see_other }
        format.json { render json: { error: "Access denied" }, status: :forbidden }
      end
      return
    end

    # Handle both string and array parameters
    ids_param = params[:ids]
    if ids_param.nil?
      respond_to do |format|
        format.html { redirect_to learn_and_earns_path, alert: "No entries selected for deletion.", status: :see_other }
        format.json { render json: { error: "No IDs provided" }, status: :bad_request }
      end
      return
    end

    # Convert to array and sanitize
    entry_ids = Array(ids_param).flatten
                  .map { |id| id.to_s.strip }
                  .reject { |id| id.empty? || id == "0" }
                  .map(&:to_i)
                  .uniq
                  .reject(&:zero?)

    Rails.logger.info "Bulk delete requested for IDs: #{entry_ids.inspect}"

    if entry_ids.empty?
      respond_to do |format|
        format.html { redirect_to learn_and_earns_path, alert: "Invalid entry IDs provided.", status: :see_other }
        format.json { render json: { error: "Invalid IDs" }, status: :bad_request }
      end
      return
    end

    begin
      # Find entries to delete
      entries = LearnAndEarn.where(id: entry_ids)
      found_count = entries.count

      Rails.logger.info "Found #{found_count} entries out of #{entry_ids.length} requested IDs"

      if found_count == 0
        respond_to do |format|
          format.html { redirect_to learn_and_earns_path, alert: "No valid entries found for deletion. They may have been deleted already.", status: :see_other }
          format.json { render json: { error: "Entries not found" }, status: :not_found }
        end
        return
      end

      # Perform deletion with proper association handling
      destroyed_entries = entries.destroy_all
      destroyed_count = destroyed_entries.length

      Rails.logger.info "Successfully deleted #{destroyed_count} entries with associated records"

      respond_to do |format|
        if destroyed_count > 0
          format.html { redirect_to learn_and_earns_path, notice: "Successfully deleted #{destroyed_count} Learn & Earn entries.", status: :see_other }
          format.json { render json: { message: "Deleted #{destroyed_count} entries", count: destroyed_count }, status: :ok }
        else
          format.html { redirect_to learn_and_earns_path, alert: "Failed to delete selected entries.", status: :see_other }
          format.json { render json: { error: "Deletion failed" }, status: :unprocessable_entity }
        end
      end
    rescue StandardError => e
      Rails.logger.error "Error in bulk delete: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      respond_to do |format|
        format.html { redirect_to learn_and_earns_path, alert: "An error occurred during bulk deletion. Please try again.", status: :see_other }
        format.json { render json: { error: "Bulk deletion error" }, status: :internal_server_error }
      end
    end
  end

  def edit
  end

  def update
    # Debug: Log the parameters
    Rails.logger.info "Update params: #{params.inspect}"
    Rails.logger.info "Request method: #{request.method}"
    Rails.logger.info "Content type: #{request.content_type}"
    Rails.logger.info "Raw post data: #{request.raw_post}"

    # Check if learn_and_earn parameter exists
    if params[:learn_and_earn].blank?
      Rails.logger.error "learn_and_earn parameter is missing!"
      Rails.logger.error "Full params: #{params.to_unsafe_h.inspect}"

      # Redirect back with error message
      respond_to do |format|
        format.html { redirect_to edit_learn_and_earn_path(@learn_and_earn), alert: "Form submission failed. Please try again." }
        format.json { render json: { error: "Form data missing" }, status: :bad_request }
      end
      return
    end

    respond_to do |format|
      if current_user.admin?
        if @learn_and_earn.update(learn_and_earn_params)
          format.html { redirect_to @learn_and_earn, notice: "Entry updated successfully." }
        else
          format.html { render :edit, status: :unprocessable_entity }
        end
      else
        if @learn_and_earn.update(user_proof_params)
          format.html { redirect_to @learn_and_earn, notice: "Proof submitted successfully." }
        else
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end
  end

  def destroy
    # Authorization check
    unless current_user.admin? || @learn_and_earn.user == current_user
      respond_to do |format|
        format.html { redirect_to root_path, alert: "Access denied. You can only delete your own entries.", status: :see_other }
        format.json { render json: { error: "Access denied" }, status: :forbidden }
      end
      return
    end

    # Store entry details for notice message
    entry_details = "Entry: #{@learn_and_earn.link.truncate(50)}"

    begin
      if @learn_and_earn.destroy
        puts "Data delete successful"
        respond_to do |format|
          format.html { redirect_to learn_and_earns_url, notice: "#{entry_details} was successfully deleted.", status: :see_other }
          format.json { head :no_content }
        end
      else
        respond_to do |format|
          format.html { redirect_to learn_and_earns_url, alert: "Failed to delete #{entry_details}. Please try again.", status: :see_other }
          format.json { render json: { error: "Deletion failed" }, status: :unprocessable_entity }
        end
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html { redirect_to learn_and_earns_url, alert: "The entry could not be found. It may have been deleted already.", status: :see_other }
        format.json { render json: { error: "Entry not found" }, status: :not_found }
      end
    rescue StandardError => e
      Rails.logger.error "Error deleting LearnAndEarn #{@learn_and_earn.id}: #{e.message}"
      respond_to do |format|
        format.html { redirect_to learn_and_earns_url, alert: "An error occurred while deleting the entry. Please try again.", status: :see_other }
        format.json { render json: { error: "Deletion error" }, status: :internal_server_error }
      end
    end
  end

  def approve
    if @learn_and_earn.update(status: "approved")
      redirect_to admin_dashbord_index_path, notice: "Entry approved successfully."
    else
      redirect_to admin_dashbord_index_path, alert: "Failed to approve entry."
    end
  end

  def reject
    if @learn_and_earn.update(status: "rejected")
      redirect_to admin_dashbord_index_path, notice: "Entry rejected successfully."
    else
      redirect_to admin_dashbord_index_path, alert: "Failed to reject entry."
    end
  end

  private

    def set_learn_and_earn
      @learn_and_earn = LearnAndEarn.find_by(id: params[:id])

      if @learn_and_earn.nil?
        respond_to do |format|
          format.html { redirect_to learn_and_earns_path, alert: "The requested entry could not be found. It may have been deleted already.", status: :see_other }
          format.json { render json: { error: "Entry not found" }, status: :not_found }
        end
        nil
      end
    end

    def authorize_admin!
      redirect_to root_path, alert: "Admins only!" unless current_user.admin?
    end

    def authorize_user_or_admin!
      return if current_user.admin?
      redirect_to root_path, alert: "Access denied." unless @learn_and_earn.user == current_user
    end

    def learn_and_earn_params
      params.require(:learn_and_earn).permit(:user_id, :link, :social_post, :proof, :status, :file)
    end

    def user_proof_params
      # params.require(:learn_and_earn).permit(:proof)
      # params.require(:learn_and_earn).permit(:link, :social_post, :proof, :status, :user_id)
      params.require(:learn_and_earn).permit(:proof, :status)
    end

    def distribute_to_all_users(template_entry)
      created_count = 0

      User.all.find_each(batch_size: 100) do |user|
        # Skip if user already has this entry
        next if LearnAndEarn.exists?(user: user, link: template_entry.link)

        learn_and_earn = LearnAndEarn.new(
          link: template_entry.link,
          social_post: template_entry.social_post,
          status: "pending",
          user: user
        )
        learn_and_earn.skip_proof_validation = true

        # Validate first to catch any other issues
        if learn_and_earn.valid?
          if learn_and_earn.save
            created_count += 1
          end
        else
          Rails.logger.error "Failed to validate LearnAndEarn for user #{user.id}: #{learn_and_earn.errors.full_messages.join(', ')}"
        end
      end

      created_count
    end

    def process_bulk_import
      uploaded_file = params[:learn_and_earn][:file]
      created_entries = []

      begin
        # Detect file extension
        extension = File.extname(uploaded_file.original_filename).delete(".").downcase

        # Read spreadsheet
        spreadsheet = begin
          if extension.in?([ "csv" ])
            Roo::CSV.new(uploaded_file.tempfile.path)
          else
            Roo::Spreadsheet.open(uploaded_file.tempfile.path, extension: extension)
          end
        rescue => e
          Rails.logger.error "Error opening spreadsheet: #{e.message}"
          redirect_to new_learn_and_earn_path, alert: "Error reading file: #{e.message}. Please ensure it's a valid Excel/CSV file."
          return
        end

        header = spreadsheet.row(1)

        # Map column indices
        link_col = header.index { |h| h.to_s.downcase.include?("link") } || 0
        social_post_col = header.index { |h| h.to_s.downcase.include?("social") || h.to_s.downcase.include?("post") } || 1

        (2..spreadsheet.last_row).each do |i|
          row = spreadsheet.row(i)

          link_value = row[link_col]&.to_s&.strip
          social_post_value = row[social_post_col]&.to_s&.strip

          next if link_value.blank?

          # Create LearnAndEarn entry
          learn_and_earn = LearnAndEarn.new(
            link: link_value,
            social_post: social_post_value.presence || "Imported from file",
            status: "pending",
            user: current_user
          )

          learn_and_earn.skip_proof_validation = true

          if learn_and_earn.save
            created_entries << learn_and_earn
          end
        end

        if created_entries.any?
          redirect_to learn_and_earns_path, notice: "Successfully created #{created_entries.count} Learn & Earn entries from file."
        else
          redirect_to new_learn_and_earn_path, alert: "No valid entries found in the uploaded file."
        end

      rescue => e
        Rails.logger.error "Error processing bulk import: #{e.message}"
        redirect_to new_learn_and_earn_path, alert: "Error processing file: #{e.message}"
      end
    end
end
