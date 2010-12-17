migration 2, :create_workshops do
  up do
    create_table :workshops do
      column :id, Integer, :serial => true
      column :account_id, Integer
      column :location_id, Integer
      column :title, String
      column :description, String
      column :event_uid, String
      column :duration_in_minutes, Integer, :default => 60
      column :invitees_can_propose_dates, TrueClass, :default => true
      column :status, Integer, :default => Workshop::OPEN
      column :created_at, DateTime
      column :expires_at, DateTime
    end
  end

  down do
    drop_table :workshops
  end
end
