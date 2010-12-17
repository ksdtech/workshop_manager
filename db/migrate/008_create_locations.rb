migration 8, :create_locations do
  up do
    create_table :locations do
      column :id, Integer, :serial => true
      column :name, String
    end
  end

  down do
    drop_table :locations
  end
end
