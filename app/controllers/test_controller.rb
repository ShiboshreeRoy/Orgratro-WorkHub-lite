class TestController < ApplicationController
  def index
    render plain: "user_signed_in?: #{user_signed_in?}, current_user: #{current_user}"
  end
end
