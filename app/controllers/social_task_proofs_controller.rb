class SocialTaskProofsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_proof, only: [:show]


   def index
  @proofs = current_user.social_task_proofs
                        .order(created_at: :desc)
                        .page(params[:page])
                        .per(10)  # Adjust the number of items per page
   
end


    def new
        @proof = current_user.social_task_proofs.new
    end


   def create
  @proof = current_user.social_task_proofs.new(proof_params)
  @proof.status = :pending

  if @proof.save
    redirect_to @proof, notice: 'Proof submitted — waiting for admin approval.'
  else
    flash.now[:alert] = 'Could not submit proof: ' + @proof.errors.full_messages.join(", ")
    render :new, status: :unprocessable_entity
  end
end



    def show
    end


    private


    def set_proof
        @proof = current_user.social_task_proofs.find(params[:id])
    end


    def proof_params
        params.require(:social_task_proof).permit(:post_url, :task_id)
    end

end