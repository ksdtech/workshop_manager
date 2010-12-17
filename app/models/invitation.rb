class Invitation
  include DataMapper::Resource
  
  # Invite type
  INITIAL   = 1
  UPDATE    = 2
  REMINDER  = 3
  FINALIZED = 4
  CANCELLED = 5

  # Properties
  property :id, Serial
  property :account_id, Integer
  property :token, String
  property :created_at, DateTime
  
  # Associations
  belongs_to :account
  belongs_to :workshop
  has n, :votes
  
  before :create, :make_token
  
  def full_name
    account.full_name
  end
  
  def email
    account.email
  end
  
  def name_or_email
    (full_name.nil? || full_name.empty?) ? email : full_name
  end
  
  def url
    # TODO fix this
    "http://localhost:3000/invitations/votes/#{self.id}?invite=#{self.token}"
  end
  
  def voting_summary_s
    votes_cast > 0 ? "Voted" : "Has Not Voted"
  end
  
  def votes_cast
    votes.count(:free_busy => [1, 2, 3])
  end
  
  private
  
  def make_token
    self.token = rand(36**8).to_s(36)
  end
end
