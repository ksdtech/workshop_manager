migration 5, :create_activities do
  up do
    create_table :activities do
      column :id, Integer, :serial => true
      column :account_id, Integer
      column :workshop_id, Integer
      column :description, String
      column :created_at, DateTime
      column :expires_at, DateTime
    end
  end

  down do
    drop_table :activities
  end
end
