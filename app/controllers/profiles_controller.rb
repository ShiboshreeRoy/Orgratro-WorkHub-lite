class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [ :show ]

  def index
    @user = current_user
    @links = Link.all
    # Only the clicks of the current user
    @clicks = current_user.clicks
  end

  def show
    @links = @user.links
    @clicks = @user.clicks
  end

  private

  def set_user
    if params[:id].present?
      @user = User.find(params[:id])
    else
      @user = current_user
    end
  end
end
