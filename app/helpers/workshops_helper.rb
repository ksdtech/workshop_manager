# Helper methods defined here can be accessed in any controller or view in the application

WorkshopManager.helpers do
  def allowed_by_invite?
    token = params[:invite]
    invitation = Invitation.first(:token => token)
    if invitation
      set_current_account(invitation.account)
      return true
    end
    false
  end
  
  def login_or_invite_required
    store_location! if store_location
    return access_denied unless allowed_by_invite? || allowed?
  end
  
  def set_location
    @location = current_account.location if current_account
    unless @location
      loc_id = params[:location] || session[:location_id]
      @location = Location.get(loc_id.to_i) || Location.first
    end
    session[:location_id] = @location.id
  end  
end