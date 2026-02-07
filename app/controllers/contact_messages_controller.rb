class ContactMessagesController < ApplicationController
  def index
    @contact_messages = ContactMessage.order(created_at: :desc)
  end

  def show
    @contact_message = ContactMessage.find(params[:id])
  end

  def new
    @contact_message = ContactMessage.new
  end

  def create
    @contact_message = ContactMessage.new(contact_message_params.merge(user: current_user))
    if @contact_message.save
      # Optionally: ContactMailer.with(contact_message: @contact_message).notify_admin.deliver_now
      redirect_to new_contact_message_path, notice: "Message sent successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @contact_message = ContactMessage.find(params[:id])
    @contact_message.destroy
    redirect_to contact_messages_path, notice: "Message deleted successfully."
  end

  private

  def contact_message_params
    params.require(:contact_message).permit(
      :name, :email, :subject, :message,
      :project_name, :project_description, :project_url,
      :address, :contact_number,
      :project_image,
      project_files: []
    )
  end
end
