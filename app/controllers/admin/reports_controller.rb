class Admin::ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!

  def index
    @q = User.ransack(params[:q])
    @users = @q.result.includes(:clicks).order(:id).page(params[:page]).per(50)
    @title = "Orgatro Woorkhub"

    respond_to do |format|
      format.html # renders app/views/reports/index.html.erb
      format.pdf do
        pdf = Prawn::Document.new

        # Header - Orgatro Woorkhub (Green)
        pdf.text "<b><font color='FFFFFF'>#{@title}</font></b>",
                 size: 18, align: :center, inline_format: true
        pdf.move_down 20
        # Table data
        table_data = [ [ "ID", "Name", "Email", "Clicks" ] ]
        @users.each do |user|
          table_data << [ user.id, user.name.presence || "N/A", user.email, user.clicks.count ]
        end

        # Table styling
        pdf.table(table_data, header: true, width: pdf.bounds.width) do |t|
          t.row(0).font_style = :bold
          t.row(0).background_color = "008000" # green header
          t.row(0).text_color = "FFFFFF" # white text
          t.row_colors = [ "F9F9F9", "FFFFFF" ] # striped rows
          t.position = :center
        end

        # Send PDF to browser
        send_data pdf.render,
                  filename: "Worgatro_Workhub_User_Reports.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end

  def user_clicks
    @q = User.ransack(params[:q])
    @users = @q.result.includes(:clicks).order(:id)

    # Chart data for Chartkick (HTML view only)
    @chart_data = @users.map { |u| [ u.name.presence || "N/A", u.clicks.count ] }

    respond_to do |format|
      format.html # renders app/views/reports/user_clicks.html.erb
      format.pdf do
        pdf = Prawn::Document.new

        # Header - User Clicks Report
        # Set background rectangle
        pdf.fill_color "008000" # green
        pdf.fill_rectangle [ 0, pdf.cursor + 25 ], pdf.bounds.width, 30

        # Set text color to white
        pdf.fill_color "FFFFFF" # white
        pdf.text_box "Orgatro Workhub",
                    at: [ 0, pdf.cursor + 25 ],
                    width: pdf.bounds.width,
                    height: 30,
                    align: :center,
                    valign: :center,
                    size: 18,
                    style: :bold

        # Reset fill color for normal text
        pdf.fill_color "000000"
        pdf.move_down 20

         pdf.text "<b><font color='008000'>User's Click Reports</font></b>",
                 size: 10, align: :center, inline_format: true
        pdf.move_down 20

        # Table data
        table_data = [ [ "ID", "Name", "Email", "Clicks" ] ]
        @users.each do |user|
          table_data << [ user.id, user.name.presence || "N/A", user.email, user.clicks.count ]
        end

        # Table styling
        pdf.table(table_data, header: true, width: pdf.bounds.width) do |t|
          t.row(0).font_style = :bold
          t.row(0).background_color = "008000"
          t.row(0).text_color = "FFFFFF"
          t.row_colors = [ "F9F9F9", "FFFFFF" ]
          t.position = :center
        end

        # Send PDF
        send_data pdf.render,
                  filename: "Orgatro_Workhub_User_Clicks_Report.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end
end
