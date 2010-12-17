migration 4, :create_votes do
  up do
    create_table :votes do
      column :id, Integer, :serial => true
      column :invitation_id, Integer
      column :proposal_id, Integer
      column :free_busy, Integer, :default => Vote::UNCAST
      column :comment, String
      column :created_at, DateTime
      column :updated_at, DateTime
    end
  end

  down do
    drop_table :votes
  end
end
