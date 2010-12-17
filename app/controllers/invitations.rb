WorkshopManager.controllers :invitations do  
  # get :index, :map => "/foo/bar" do
  #   session[:foo] = "bar"
  #   render 'index'
  # end

  get :votes, :with => :id do
    @invitation = Invitation.get(params[:id])
    @workshop = @invitation.workshop
    @can_edit = current_account && current_account.id == @invitation.account.id
    @proposals = @workshop.proposals
    @invitations = @workshop.invitations
    render 'invitations/votes'
  end

  post :update_votes, :with => :id do
    @invitation = Invitation.get(params[:id])
    params[:votes].keys.each do |vote_id|
      v = Vote.get(vote_id)
      v.update(
        :free_busy => params[:votes][vote_id],
        :comment => params[:comments][vote_id])
    end
    redirect url_for(:invitations, :votes, @invitation.id)
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