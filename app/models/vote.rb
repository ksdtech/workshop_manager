class Vote
  include DataMapper::Resource
  
  # free_busy values
  UNCAST = 0
  YES    = 1
  MAYBE  = 2
  NO     = 3
  VOTE_STRINGS = [ "Not yet voted", "Yes", "Maybe", "No" ].freeze

  # Properties
  property :id, Serial
  property :invitation_id, Integer
  property :free_busy, Integer, :default => Vote::UNCAST
  property :comment, String
  property :created_at, DateTime
  property :updated_at, DateTime

  # Associations
  belongs_to :invitation
  belongs_to :proposal
  
  def to_s
    VOTE_STRINGS[free_busy >= Vote::UNCAST && free_busy <= Vote::NO ? free_busy : Vote::UNCAST]
  end
  
  def checked?(value)
    free_busy == value ? "checked" : nil
  end
end
