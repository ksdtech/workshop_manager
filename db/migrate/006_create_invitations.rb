migration 6, :create_invitations do
  up do
    create_table :invitations do
      column :id, Integer, :serial => true
      column :account_id, Integer
      column :workshop_id, Integer
      column :token, String
      column :created_at, DateTime
    end
  end

  down do
    drop_table :invitations
  end
end
