class AddSnapshotTypeToAnalyticsSnapshots < ActiveRecord::Migration[7.2]
  def change
    add_column :analytics_snapshots, :snapshot_type, :string, default: 'daily'
    
    # Update existing records to have 'daily' as default
    AnalyticsSnapshot.update_all(snapshot_type: 'daily') if AnalyticsSnapshot.table_exists?
    
    # Add the unique index after adding the column
    add_index :analytics_snapshots, [:date, :snapshot_type], unique: true
  end
end
