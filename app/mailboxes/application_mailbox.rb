class ApplicationMailbox < ActionMailbox::Base
  # Last part is the regex for the UUID
  # Eg: email should be something like : reply+to+6bdc3f4d-0bec-4515-a284-5d916fdde489@domain.com
  REPLY_EMAIL_USERNAME_PATTERN = /^reply\+to\+([0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12})$/i.freeze

  def self.reply_match_proc
    proc do |inbound_mail_obj|
      is_a_reply_email = false
      inbound_mail_obj.mail.to.each do |email|
        username = email.split('@')[0]
        match_result = username.match(REPLY_EMAIL_USERNAME_PATTERN)
        if match_result
          is_a_reply_email = true
          break
        end
      end
      is_a_reply_email
    end
  end

  def self.default_mail_proc
    proc { |_mail| true }
  end

  # routing should be defined below the referenced procs
  routing(reply_match_proc => :conversation)
  routing(default_mail_proc => :default)
end
