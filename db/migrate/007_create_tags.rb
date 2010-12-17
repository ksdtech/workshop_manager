migration 7, :create_tags do
  up do
    create_table :tags do
      column :id, Integer, :serial => true
      column :name, String
    end
    
    create_table :tag_workshops do
      column :id, Integer, :serial => true
      column :tag_id, Integer
      column :workshop_id, Integer
    end
  end

  down do
    drop_table :tag_workshops
    drop_table :tags
  end
end
