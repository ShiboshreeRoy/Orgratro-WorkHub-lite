# app/controllers/admin/referrals_controller.rb
class Admin::ReferralsController < Admin::BaseController
  def index
    @referrals = Referral.includes(:referrer, :referred_user)
                         .order(created_at: :desc)
                         .page(params[:page])
                         .per(15)

    @total_referrals = Referral.count

    respond_to do |format|
      format.html
      format.pdf do
        pdf = Prawn::Document.new(page_size: "A4", page_layout: :landscape)
        
        # Title
        pdf.text "All Referrals", size: 24, style: :bold, align: :center
        pdf.move_down 10
        pdf.text "Total Referrals: #{@total_referrals}", size: 12, align: :center
        pdf.move_down 20

        # Table data
        table_data = [["Referrer", "Referred User", "Joined At"]]
        @referrals.each do |r|
          table_data << [
            r.referrer&.email || "N/A",
            r.referred_user&.email || "N/A",
            r.created_at.strftime("%B %d, %Y %H:%M")
          ]
        end

        pdf.table(table_data, header: true, width: pdf.bounds.width) do
          row(0).font_style = :bold
          row(0).background_color = "CCCCCC"
          self.row_colors = ["FFFFFF", "F0F0F0"]
          self.header = true
        end

        # Send PDF to browser
        send_data pdf.render,
                  filename: "referrals.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end
end
