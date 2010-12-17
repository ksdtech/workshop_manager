WorkshopManager.controllers :proposals do
  # get :index, :map => "/foo/bar" do
  #   session[:foo] = "bar"
  #   render 'index'
  # end

  get :votes, :with => :id do
    @proposal = Proposal.get(params[:id])
    @workshop = @proposal.workshop
    @proposals = @workshop.proposals
    @invitations = @workshop.invitations
    @invitation = @workshop.invitations.first(:account_id => current_account.id)
    render 'proposals/votes'
  end
  
  post :finalize, :with => :id do
    proposal = Proposal.get(params[:id])
    workshop = proposal.workshop.finalize!(proposal, true)
    redirect url_for(:workshops, :index)
  end

  post :update_votes, :with => :id do
    @proposal = Proposal.get(params[:id])
    params[:votes].keys.each do |vote_id|
      v = Vote.get(vote_id)
      v.update(
        :free_busy => params[:votes][vote_id],
        :comment => params[:comments][vote_id])
    end
    redirect url_for(:proposals, :votes, @proposal.id)
  end

  # get :sample, :map => "/sample/url", :provides => [:any, :js] do
  #   case content_type
  #     when :js then ...
  #     else ...
  # end

  # get :foo, :with => :id do
  #   "Maps to url '/foo/#{params[:id]}'"
  # end

  # get "/example" do
  #   "Hello world!"
  # end

  
end