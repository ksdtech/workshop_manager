migration 3, :create_proposals do
  up do
    create_table :proposals do
      column :id, Integer, :serial => true
      column :account_id, Integer
      column :workshop_id, Integer
      column :selected, TrueClass, :default => false
      column :start_time, DateTime
      column :created_at, DateTime
      column :updated_at, DateTime
    end
  end

  down do
    drop_table :proposals
  end
end
