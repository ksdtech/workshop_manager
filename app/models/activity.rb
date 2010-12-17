class Activity
  include DataMapper::Resource
  
  # Properties
  property :id, Serial
  property :account_id, Integer
  property :workshop_id, Integer
  property :description, String
  property :created_at, DateTime

  # Associations
  belongs_to :account
  belongs_to :workshop
end
