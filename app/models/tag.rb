class Tag
  include DataMapper::Resource

  # Properties
  property :id, Serial
  property :name, String
  
  # Associations
  has n, :workshops, :through => Resource
end
