class CreateUserActivityLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :user_activity_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :action
      t.text :details
      t.datetime :timestamp

      t.timestamps
    end
  end
end
