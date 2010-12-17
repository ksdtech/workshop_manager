migration 1, :create_accounts do
  up do
    create_table :accounts do
      column :id, Integer, :serial => true
      column :location_id, Integer
      column :email, String
      column :full_name, String
      column :crypted_password, String
      column :salt, String
      column :role, String
    end
  end

  down do
    drop_table :accounts
  end
end
