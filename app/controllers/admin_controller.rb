class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  protect_from_forgery with: :exception

  skip_before_action :verify_authenticity_token, only: [:update, :toggle_suspend]
  before_action :set_user, only: [:show, :edit, :update, :destroy, :toggle_suspend]

  # Dashboard / Users list
  def index
    @q = User.ransack(params[:q])
    @users = @q.result(distinct: true).order(created_at: :desc)
  end

  # Show individual user
  def show
    # @user is already set by set_user
  end

  # New user form handled in index view
  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to admin_index_path, notice: "User created successfully."
    else
      flash.now[:alert] = @user.errors.full_messages.join(", ")
      @q = User.ransack(params[:q])
      @users = @q.result(distinct: true)
      render "admin/index"
    end
  end

  # Edit user form handled in index view
  def edit
    # @user is already set by set_user
  end

  # Update user attributes
  def update
    if @user.update(user_update_params)
      respond_to do |format|
        format.html { redirect_to admin_index_path, notice: "User updated successfully." }
        format.turbo_stream
      end
    else
      redirect_to admin_index_path, alert: @user.errors.full_messages.join(", ")
    end
  end

  # Toggle suspend/unsuspend user
  def toggle_suspend
    @user.suspended = !@user.suspended
    if @user.save
      status = @user.suspended ? "suspended" : "unsuspended"
      redirect_to admin_index_path, notice: "User successfully #{status}."
    else
      redirect_to admin_index_path, alert: "Failed to change suspend status."
    end
  end

 def destroy
  # Ensure we don't delete the current admin user
  if @user == current_user
    redirect_to admin_index_path, alert: "You cannot delete your own account."
    return
  end
  
  if @user.destroy
    redirect_to admin_index_path, notice: "User deleted successfully."
  else
    redirect_to admin_index_path, alert: "Failed to delete user."
  end
 end

 # Update user balance
 def update_balance
  @user = User.find(params[:id])
  new_balance = params[:user][:balance].to_d
  old_balance = @user.balance
  balance_difference = new_balance - old_balance
  
  if @user.update(balance: new_balance)
    # Create a transaction record for the balance adjustment
    if balance_difference != 0
      transaction_type = balance_difference > 0 ? 'credit' : 'debit'
      amount = balance_difference.abs
      
      @user.transactions.create!(
        amount: amount,
        transaction_type: transaction_type,
        description: "Balance manually adjusted by admin from #{old_balance} to #{new_balance}"
      )
    end
    # Touch the user to update the updated_at timestamp which may help with session refresh
    @user.touch
    redirect_to admin_index_path, notice: "User balance updated successfully."
  else
    redirect_to admin_index_path, alert: "Failed to update user balance."
  end
 end

  private

  # Only permit the allowed attributes for create
  def user_params
    params.require(:user).permit(:email, :role, :password, :password_confirmation)
  end

  # Permit attributes for update (conditionally include password)
  def user_update_params
    permitted = [:email, :role]
    if params[:user][:password].present?
      permitted += [:password, :password_confirmation]
    end
    params.require(:user).permit(permitted)
  end

  # Set user for actions
  def set_user
    @user = User.find(params[:id])
  end

  
end
