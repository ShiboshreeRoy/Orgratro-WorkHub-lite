module Admin
  class SocialTaskProofsController < Admin::BaseController
    before_action :authenticate_admin!
    before_action :set_proof, only: [ :show, :update ]

   def index
     @proofs = SocialTaskProof.includes(:user, :admin).order(created_at: :desc).page(params[:page]).per(10)
      # .per(10) sets 10 proofs per page, adjust as needed
    end


    def show
    end

    def test_image
      @proof = SocialTaskProof.find(params[:id])
      render "admin/social_task_proofs/test_image"
    end

    def update
      action = params[:approve_action]

      case action
      when "approve"
        @proof.update(status: :approved, admin: current_user, approved_at: Time.current)
        flash[:notice] = "Proof approved."
      when "reject"
        @proof.update(status: :rejected, admin: current_user)
        flash[:alert] = "Proof rejected."
      else
        flash[:alert] = "Invalid action."
      end

      redirect_to admin_social_task_proof_path(@proof)
    end

    private

    def set_proof
      @proof = SocialTaskProof.find(params[:id])
    end

    def authenticate_admin!
      redirect_to root_path, alert: "Access denied." unless current_user&.admin?
    end
  end
end
