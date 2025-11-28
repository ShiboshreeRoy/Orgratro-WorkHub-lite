class ShortLinksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :create ]
  def index
    @short_links = ShortLink.all.order(id: :desc)
  end

  def create
    @short_link = ShortLink.create(original: params[:original])
    render json: { short_url: @short_link.short_url }
  end

  def short_url
    Rails.application.routes.url_helpers.short_redirect_path(slug: slug)
  end

  def redirect
    link = ShortLink.find_by(slug: params[:slug])
    if link
      redirect_to link.original, allow_other_host: true
    else
      render plain: "Not found", status: 404
    end
  end
end
