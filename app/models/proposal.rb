class Proposal
  include DataMapper::Resource
  
  DATEFMT_YMDHM            = '%Y-%m-%d %H:%M'
  DATEFMT_RFC2445_FLOATING = "%Y%m%dT%H%M00"
  DATEFMT_GCAL             = "%Y-%m-%dT%H:%M:00%Z"
  
  # Properties
  property :id, Serial
  property :selected, Boolean, :default => false
  property :start_time, DateTime
  property :created_at, DateTime
  property :updated_at, DateTime

  # Associations
  belongs_to :account
  belongs_to :workshop
  has n, :votes
  
  def end_time
    start_time + (self.workshop.duration_in_minutes + 0.1)/1440.0
  end
  
  def start_time_s
    start_time.strftime(Proposal::DATEFMT_YMDHM)
  end
  
  def end_time_s
    end_time.strftime(Proposal::DATEFMT_YMDHM)
  end
    
  def voting_summary
    all_votes = [ self.workshop.invitations.count, 0, 0, 0 ]
    self.votes.each do |vote|
      fb = vote.free_busy
      if fb >= Vote::YES && fb <= Vote::NO
        all_votes[fb] += 1
        all_votes[Vote::UNCAST] -= 1 if all_votes[Vote::UNCAST] > 0
      end
    end
    all_votes
  end
  
  def voting_summary_s
    total_uncast, total_yes, total_maybe, total_no = voting_summary
    "Yes: #{total_yes}, Maybe: #{total_maybe}, No: #{total_no}, Not yet cast: #{total_uncast}"
  end
  
  def vote_for_invitation(invitation)
    self.votes.first_or_create(:invitation_id => invitation.id)
  end
  
  # authenticate as bacich or kent tech workshop user
  # send jsonc to https://www.google.com/calendar/feeds/default/private/full?alt=jsonc
  def create_event_jsonc(invitations)
    attendees = invitations.map do |invitation|
      {
        'displayName' => invitation.name_or_email,
        'email'       => invitation.email,
        'rel'         => 'attendee',
        'status'      => 'invited',
      }
    end
    attendees << {
      'displayName' => configatron.gcal.user_name,
      'email'       => configatron.gcal.user_email,
      'rel'         => 'organizer',
      'status'      => 'accepted',
    }
    
    {
      'data' => {
        'title'        => self.workshop.title,
        'details'      => self.workshop.description,
        'when' => [ { 
            'start' => start_time.strftime(Proposal::DATEFMT_GCAL),
            'end' => end_time.strftime(Proposal::DATEFMT_GCAL)
        } ],
        'attendees' => attendees,
        'transparency' => 'opaque',
        'visibility'   => 'default',
        'status'       => 'confirmed',
        'sequence'     => 0, 
        'canEdit'      => true,
        'guestsCanInviteOthers' => true, 
        'guestsCanModify'       => true, 
        'guestsCanSeeGuests'    => true,
        'anyoneCanAddSelf'      => false
      }
    }.to_json
  end
  
  def ical_escape(s)
    s.gsub(/\n\r?|\r\n?|,|;|:|\\/) do |match|
      if ["\n", "\r", "\n\r", "\r\n"].include?(match)
        '\\n'
      elsif match == ':'
        '":"'
      else
        "\\#{match}"
      end
    end
  end
  
  def ical_invite_body(invitee_email, invitee_name=nil)
    dtstamp = Time.now.strftime(Proposal::DATEFMT_RFC2445_FLOATING)
    dtstart = start_time.strftime(Proposal::DATEFMT_RFC2445_FLOATING)
    dtend   = end_time.strftime(Proposal::DATEFMT_RFC2445_FLOATING)
    organizer_cn = ical_escape(configatron.gcal.user_cn)
    organizer_email = configatron.gcal.user_email
    invitee_cn = ical_escape(invitee_name || invitee_email)
    
    return <<"EOBODY"
BEGIN:VCALENDAR
VERSION:2.0
CALSCALE:GREGORIAN
METHOD:REQUEST
BEGIN:VEVENT
DTSTART:#{dtstart}
DTEND:#{dtend}
DTSTAMP:#{dtstamp}
LAST-MODIFIED:#{dtstamp}
SUMMARY:#{ical_escape(self.workshop.title)}
DESCRIPTION:#{ical_escape(self.workshop.description)}
ORGANIZER;CN=#{organizer_cn}:mailto:#{organizer_email}
UID:#{self.workshop.event_uid}@google.com
ATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=ACCEPTED;
 RSVP=TRUE;CN=#{organizer_cn};
 X-NUM-GUESTS=0:mailto:#{organizer_email}
ATTENDEE;CUTYPE=INDIVIDUAL;ROLE=OPT-PARTICIPANT;PARTSTAT=NEEDS-ACTION;
 RSVP=TRUE;CN=#{invitee_cn};
 X-NUM-GUESTS=0:mailto:#{invitee_email}
SEQUENCE:0
STATUS:CONFIRMED
TRANSP:OPAQUE
END:VEVENT
END:VCALENDAR
EOBODY
  end
end
