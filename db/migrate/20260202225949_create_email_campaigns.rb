class CreateEmailCampaigns < ActiveRecord::Migration[7.2]
  def change
    create_table :email_campaigns do |t|
      t.string :name
      t.string :subject
      t.text :content
      t.string :sender_email
      t.string :status
      t.datetime :scheduled_at
      t.datetime :sent_at
      t.integer :recipients_count
      t.integer :opened_count
      t.integer :clicked_count
      t.integer :bounce_count

      t.timestamps
    end
  end
end
