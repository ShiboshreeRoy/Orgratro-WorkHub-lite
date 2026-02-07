class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
    @links = Link.all
    # Only the clicks of the current user
    @clicks = current_user.clicks
  end
end
