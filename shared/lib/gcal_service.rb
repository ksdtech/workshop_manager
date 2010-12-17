# gdata.rb
# just enough google to get us going

require 'curb'
require 'json'

class GcalService
  LOGIN_URL = 'https://www.google.com/accounts/ClientLogin'
  CREATE_EVENT_JSONC_URL = 'https://www.google.com/calendar/feeds/default/private/full?alt=jsonc'
  APP_ID = 'ksd-workshopmanager-v1'
  
  def parse_body_form_encoded(body_str)
    body_str.split(/\r?\n/).inject({}) do |h, p|
      prop, value = p.split(/\=/, 2)
      h[prop] = value
      h
    end
  end
  
  def parse_response_headers(header_str)
    header_str.split(/\r?\n/).inject({}) do |h, p|
      prop, value = p.split(/: /, 2)
      h[prop] = value
      h
    end
  end
  
  def login_token(user_email, password)
    login_data = "accountType=HOSTED&Email=#{user_email}&Passwd=#{password}&source=#{APP_ID}&service=cl"
    c = Curl::Easy.new(LOGIN_URL)
    c.http_post(login_data)
    return nil unless c.response_code == 200
    params = parse_body_form_encoded(c.body_str)
    params['Auth']
  end
  
  def get_jsonc(url, auth_token, redirects=0)
    c = Curl::Easy.new(url)
    c.headers['Authorization'] = "GoogleLogin auth=#{auth_token}"
    c.headers['Content-Type'] = 'application/json'
    c.http_get
    if [301, 302].include? c.response_code
      return nil if redirects == 10
      resp_headers = parse_response_headers(c.header_str)
      c = get_jsonc(resp_headers['Location'], auth_token, redirects+1)
    end
    c
  end
  
  def post_jsonc(url, auth_token, jsonc, redirects=0)
    c = Curl::Easy.new(url)
    c.headers['Authorization'] = "GoogleLogin auth=#{auth_token}"
    c.headers['Content-Type'] = 'application/json'
    c.http_post(jsonc)
    if [301, 302].include? c.response_code
      return nil if redirects == 10
      
      # redirect with gsessiond
      resp_headers = parse_response_headers(c.header_str)
      c = post_jsonc(resp_headers['Location'], auth_token, jsonc, redirects+1)
    end
    c
  end
  
  def create_calendar_event(user_email, password, jsonc)
    auth_token = login_token(user_email, password)
    return nil unless auth_token
    
    # should return 201 created on success
    c = post_jsonc(CREATE_EVENT_JSONC_URL, auth_token, jsonc)
    return nil unless c && c.response_code == 201

    # use ['data']['alternateLink'] or ['data']['id']
    JSON.parse(c.body_str)
  end
  
  def fetch_calendar_event(user_email, password, eid)
    auth_token = login_token(user_email, password)
    return nil unless auth_token
    
    event_url = "https://www.google.com/calendar/feeds/#{user_email}/private/full/#{eid}?alt=jsonc"
    c = get_jsonc(event_url, auth_token)
    puts c ? c.response_code : "nil response"    
    return nil unless c && c.response_code == 200
    
    JSON.parse(c.body_str)
  end
end

