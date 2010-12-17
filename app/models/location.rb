class Location
  include DataMapper::Resource

  # Properties
  property :id, Serial
  property :name, String
  
  # Associations
  has n, :accounts
  has n, :workshops
end
