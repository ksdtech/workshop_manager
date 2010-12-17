##
# Mailer methods can be defined using the simple format:
#
# email :registration_email do |name, user|
#   from 'admin@site.com'
#   to   user.email
#   subject 'Welcome to the site!'
#   locals  :name => name
#   content_type 'text/html'       # optional, defaults to plain/text
#   via     :sendmail              # optional, to smtp if defined, otherwise sendmail
#   render  'registration_email'
# end
#
# You can set the default delivery settings from your app through:
#
#   set :delivery_method, :smtp => {
#     :address         => 'smtp.yourserver.com',
#     :port            => '25',
#     :user_name       => 'user',
#     :password        => 'pass',
#     :authentication  => :plain, # :plain, :login, :cram_md5, no auth by default
#     :domain          => "localhost.localdomain" # the HELO domain provided by the client to the server
#   }
#
# or sendmail (default):
#
#   set :delivery_method, :sendmail
#
# or for tests:
#
#   set :delivery_method, :test
#
# and then all delivered mail will use these settings unless otherwise specified.
#

WorkshopManager.mailer :invite do
  email :initial do |invitation|
    workshop = invitation.workshop
    
    from    workshop.author_email
    to      invitation.email
    subject "You're invited to a workshop: #{workshop.title}"
    locals  :invitation => invitation, :workshop => workshop
    
    render 'invite/initial_invite'
  end 
  
  email :finalized do |invitation, proposal|
    workshop = invitation.workshop
    
    from     workshop.author_email
    to       invitation.email
    subject  "The workshop #{workshop.title} has been scheduled"
    locals   :invitation => invitation, :workshop => workshop, :selected_proposal => proposal
    provides :plain
    
    add_multipart_alternate_header
    text_part(render('invite/finalized'))
    part(:content_type => "text/calendar; charset=UTF-8; method=REQUEST", 
      :body => proposal.ical_invite_body(invitation.email))
  end 
end