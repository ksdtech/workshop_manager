class Workshop
  include DataMapper::Resource
  include DataMapper::Validate
  
  # status values
  PENDING   = 1
  OPEN      = 2
  EXPIRING  = 3
  EXPIRED   = 4
  FINALIZED = 5
  CANCELED  = 6
  DELETED   = 7
  STATUS_STRINGS = ["", "Pending", "Open", "Expiring", "Expired", "Finalized", "Canceled", "Closed", "Deleted"]

  # Properties
  property :id, Serial
  property :location_id, Integer
  property :title, String
  property :description, String
  property :event_uid, String
  property :duration_in_minutes, Integer, :default => 60
  property :invitees_can_propose_dates, Boolean, :default => true
  property :status, Integer, :default => Workshop::OPEN
  property :created_at, DateTime
  property :expires_at, DateTime
  
  # Associations
  belongs_to :account
  belongs_to :location
  has n, :invitations
  has n, :proposals
  has n, :tags, :through => Resource
  
  # Validations
  validates_presence_of :title
  
  before :create, :set_expiration
  
  def status_s
    Workshop::STATUS_STRINGS[status >= PENDING && status <= DELETED ? status : 0]
  end
  
  def author_name
    account.full_name
  end
  
  def author_email
    account.email
  end
  
  def author_password
    account.crypted_password && account.salt ? account.password_clean : nil
  end
  
  def default_invitation
    invitations.first(:account_id => account.id) || invitations.first
  end
  
  def invitee_emails
    invitations.map { |i| i.email }
  end
  
  def uncast_invitations
    invitations.reject { |i| i.votes_cast != 0 }
  end
  
  def start_times
    proposals.map { |p| p.start_time_s }
  end
  
  def finalize!(proposal, send_emails=true)
    found = false
    proposals.each do |p|
      if p.id == proposal.id
        found = true
        p.selected = true
      else
        p.selected = false
      end
      p.save
    end
    if found
      # add event to "workshops calendar"
      jsonc = proposal.create_event_jsonc(self.invitations)
      new_event = GcalService.new(configatron.gcal.app_id).create_calendar_event(
        configatron.gcal.user_email, 
        configatron.gcal.password, 
        jsonc)
      self.event_uid = new_event ? new_event['data']['id'] : nil
      
      # finalize the workshop
      self.status = Workshop::FINALIZED
      self.save
      
      if send_emails
        self.invitations.each do |invitation|
          WorkshopManager.deliver(:invite, :finalized, invitation, proposal)
        end
      end
    end
    found
  end
  
  def selected_proposal
    proposals.first(:selected => true)
  end
  
  def update_invitations(invitee_emails, invites=0)
    current_invitees = self.invitee_emails
    invitee_emails.uniq.each do |invitee_email|
      invitee = Account.first(:email => invitee_email)
      unless invitee
        invitee = self.location.accounts.create(
          :email => invitee_email,
          :role => 'staff')
      end
      if current_invitees.include?(invitee_email)
        current_invitees.delete(invitee_email)
      elsif invitee
        invitation = self.invitations.create
        invitation.account = invitee
        invitation.save!
      end
    end
    current_invitees.each do |invitee_email|
      account = Account.first(:email => invitee_email)
      if account
        invitation = self.invitations.first(:account => account)
        invitation.destroy if invitation
      end
    end
    case invites
    when Invitation::INITIAL
      self.invitations.each do |invitation|
        WorkshopManager.deliver(:invite, :initial, invitation)
      end
    when Invitation::UPDATE
      self.invitations.each do |invitation|
        WorkshopManager.deliver(:invite, :update, invitation)
      end
    when Invitation::REMINDER
      self.invitations.each do |invitation|
        WorkshopManager.deliver(:invite, :reminder, invitation)
      end
    else
    end
  end
  
  def update_proposals(start_times, account)
    current_start_times = self.start_times
    start_times.each do |start_time|
      if current_start_times.include?(start_time)
        current_start_times.delete(start_time)
      else
        begin
          proposal = self.proposals.create(:start_time => DateTime.strptime(start_time, Proposal::DATEFMT_YMDHM))
        rescue
          logger.info("update_proposals: invalid start_time: #{start_time}")
          next
        end
        proposal.account = account
        proposal.save!
      end
    end
    current_start_times.each do |start_time|
      dt = DateTime.strptime(start_time, Proposal::DATEFMT_YMDHM)
      proposal = self.proposals.first(:start_time => dt)
      proposal.destroy if proposal
    end
  end
  
  def self.parse_invitees(params)
    invitees = params[:invitees].split(/[\s,]/).reject { |e| e.nil? || !e.match(Account.email_format) }
    invitees.map { |e| e.downcase }.uniq
  end
  
  def self.parse_start_times(params)
    start_times = []
    1.upto(5) do |i|
      start_date = params["start_#{i}_date".to_sym]
      start_time = params["start_#{i}_time".to_sym]
      if !(start_date.nil? || start_date.empty?)
        start_time = "12:00" if (start_time.nil? || start_time.empty?)
        start_times << "#{start_date} #{start_time}".strip
      end
    end
    start_times
  end
  
  private
  
  def set_expiration
    expires_at = Date.today + 30
  end
end
