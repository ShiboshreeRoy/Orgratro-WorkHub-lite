module Admin
    class SocialTaskProofsController < Admin::BaseController
        #before_action :authenticate_admin! # implement this helper according to your auth
        before_action :set_proof, only: [:show, :update]


        def index
            @proofs = SocialTaskProof.order(created_at: :desc).page(params[:page])
        end


        def show
        end


# PATCH/PUT /admin/social_task_proofs/:id
        def update
            action = params[:approve_action]


            case action
            when 'approve'
                @proof.update(status: :approved, admin: current_user, approved_at: Time.current)
# optional: give user credit, send notification
                flash[:notice] = 'Proof approved.'
            when 'reject'
                @proof.update(status: :rejected, admin: current_user)
                flash[:alert] = 'Proof rejected.'
            else
                flash[:alert] = 'Unknown action.'
            end


            redirect_to admin_social_task_proof_path(@proof)
        end


private


        def set_proof
            @proof = SocialTaskProof.find(params[:id])
        end
    end
end