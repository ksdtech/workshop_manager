class WorkshopManager < Padrino::Application
  register Padrino::Mailer
  register Padrino::Helpers
  register Padrino::Admin::AccessControl

  ##
  # Application configuration options
  #
  # set :raise_errors, true     # Show exceptions (default for development)
  # set :public, "foo/bar"      # Location for static assets (default root/public)
  # set :reload, false          # Reload application files (default in development)
  # set :default_builder, "foo" # Set a custom form builder (default 'StandardFormBuilder')
  # set :locale_path, "bar"     # Set path for I18n translations (defaults to app/locale/)
  # enable  :sessions           # Disabled by default
  # disable :flash              # Disables rack-flash (enabled by default if sessions)
  # layout  :my_layout          # Layout can be in views/layouts/foo.ext or views/foo.ext (default :application)
  #

  ##
  # You can configure for a specified environment like:
  #
  #   configure :development do
  #     set :foo, :bar
  #     disable :asset_stamp # no asset timestamping for dev
  #   end
  #

  ##
  # You can manage errors like:
  #
  #   error 404 do
  #     render 'errors/404'
  #   end
  #
 
  before { login_or_invite_required }
  
  access_control.roles_for :any do |role|
    role.protect "/"
    role.allow   "/workshops"
    role.protect "/workshops/edit"
    role.protect "/workshops/update"
   end
  
  set :delivery_method, :smtp => { 
    #    :authentication => configatron.smtp.authentication,
    #    :user_name      => configatron.smtp.user_name,
    #    :password       => configatron.smtp.password,
    :address              => configatron.smtp.address,
    :port                 => configatron.smtp.port,
    :enable_starttls_auto => configatron.smtp.enable_starttls_auto
  }
  set :mailer_defaults, :from => configatron.mailer.from
  
end