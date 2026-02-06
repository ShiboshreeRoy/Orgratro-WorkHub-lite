class LearnAndEarnsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_learn_and_earn, only: %i[show edit update destroy track_click]
  before_action :authorize_admin!, only: %i[new create bulk_create]
  before_action :authorize_user_or_admin!, only: %i[edit update destroy]

  def index
    if current_user.admin?
      # For admins: show only pending and rejected entries (hide approved)
      @learn_and_earns = LearnAndEarn.includes(:user)
                                    .where.not(status: 'approved')
                                    .order(created_at: :desc)
                                    .page(params[:page])
                                    .per(10)
      @users = User.all
    else
      # For regular users: show their own entries
      @learn_and_earns = current_user.learn_and_earns
                                    .order(created_at: :desc)
                                    .page(params[:page])
                                    .per(10)
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
          format.html { redirect_to learn_and_earns_path, notice: "Learn & Earn entry successfully created." }
          format.json { render :show, status: :created, location: @learn_and_earn }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @learn_and_earn.errors, status: :unprocessable_entity }
        end
      end
    end
  end
  
  def bulk_create
    # Auto-send to all users functionality - create template entries for all users
    created_count = 0
    
    User.all.each do |user|
      learn_and_earn = LearnAndEarn.new(
        link: "https://example.com/default-link",
        social_post: "Default social media post for earning rewards",
        status: 'pending'
      )
      learn_and_earn.user = user
      learn_and_earn.skip_proof_validation = true
      
      if learn_and_earn.save
        created_count += 1
      end
    end
    
    redirect_to learn_and_earns_path, notice: "Successfully created #{created_count} Learn & Earn entries for all users."
  end
  
  def edit
  end
  
  def update
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
    @learn_and_earn.destroy
  
    respond_to do |format|
      format.html { redirect_to learn_and_earns_url, notice: "Learn & Earn entry successfully deleted.", status: :see_other }
      format.json { head :no_content }
    end
  end
  
  def approve
    if @learn_and_earn.update(status: 'approved')
      redirect_to admin_dashbord_index_path, notice: "Entry approved successfully."
    else
      redirect_to admin_dashbord_index_path, alert: "Failed to approve entry."
    end
  end
  
  def reject
    if @learn_and_earn.update(status: 'rejected')
      redirect_to admin_dashbord_index_path, notice: "Entry rejected successfully."
    else
      redirect_to admin_dashbord_index_path, alert: "Failed to reject entry."
    end
  end
  
  private
  
    def set_learn_and_earn
      @learn_and_earn = LearnAndEarn.find(params[:id])
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
      #params.require(:learn_and_earn).permit(:link, :social_post, :proof, :status, :user_id)
      params.require(:learn_and_earn).permit(:proof, :status)
    end
    
    def process_bulk_import
      uploaded_file = params[:learn_and_earn][:file]
      created_entries = []
      
      begin
        # Detect file extension
        extension = File.extname(uploaded_file.original_filename).delete('.').downcase
        
        # Read spreadsheet
        spreadsheet = begin
          if extension.in?(['csv'])
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
        link_col = header.index { |h| h.to_s.downcase.include?('link') } || 0
        social_post_col = header.index { |h| h.to_s.downcase.include?('social') || h.to_s.downcase.include?('post') } || 1
        
        (2..spreadsheet.last_row).each do |i|
          row = spreadsheet.row(i)
          
          link_value = row[link_col]&.to_s&.strip
          social_post_value = row[social_post_col]&.to_s&.strip
          
          next if link_value.blank?
          
          # Create LearnAndEarn entry
          learn_and_earn = LearnAndEarn.new(
            link: link_value,
            social_post: social_post_value.presence || "Imported from file",
            status: 'pending',
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
