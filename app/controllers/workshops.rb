WorkshopManager.controllers :workshops do
  get :index do
    set_location
    @workshops = @location.workshops.all(:status => [Workshop::OPEN, Workshop::EXPIRING], :order => :created_at)
    @title = "#{@location.name} Workshops"
    render 'workshops/index'
  end

  get :new do
    set_location
    render 'workshops/new'
  end

  post :create do
    location = Location.get(params[:location])
    author_email = (params[:account_email] || '').downcase
    raise "invalid email" unless author_email.match(Account.email_format)
    author = Account.first(:email => author_email)
    unless author
      author = location.accounts.create(
        :email => author_email,
        :full_name => params[:account_name],
        :role => 'staff')
    end
    set_current_account(author)
    
    workshop = author.workshops.create(:title => params[:title], 
      :description => params[:description],
      :location_id => location.id)
      
    start_times = Workshop.parse_start_times(params)
    workshop.update_proposals(start_times, author)
    
    invitee_emails = Workshop.parse_invitees(params)
    invitee_emails << author.email
    workshop.update_invitations(invitee_emails, Invitation::INITIAL)
    
    redirect url_for(:workshops, :index)
  end

  get :edit, :with => :id do
    @workshop = Workshop.get(params[:id])
    n_props = @workshop.proposals.count
    @proposals = []
    0.upto(4) do |i|
      @proposals[i] = if i < n_props
        { :date => @workshop.proposals[i].start_time.strftime("%Y-%m-%d"), 
          :time => @workshop.proposals[i].start_time.strftime("%H:%M") }
      else
        { :date => '', :time => ''}
      end
    end
    render 'workshops/edit'
  end
  
  post :update, :with => :id do
    workshop = Workshop.get(params[:id])
    workshop.update(:title => params[:title], :description => params[:description])
      
    start_times = Workshop.parse_start_times(params)
    # TODO: current_account from login or invitation cookie
    current_account = workshop.account
    workshop.update_proposals(start_times, current_account)
    
    invitee_emails = Workshop.parse_invitees(params)
    workshop.update_invitations(invitee_emails, params[:send_invitations] ? Invitation::UPDATE : 0)
    
    redirect url_for(:workshops, :index)
  end
end