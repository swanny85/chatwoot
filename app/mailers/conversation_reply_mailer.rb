class ConversationReplyMailer < ApplicationMailer
  default from: ENV.fetch('MAILER_SENDER_EMAIL', 'accounts@chatwoot.com')
  layout 'mailer'

  def reply_with_summary(conversation, message_queued_time)
    return unless smtp_config_set_or_development?

    @conversation = conversation
    @contact = @conversation.contact
    @agent = @conversation.assignee

    recap_messages = @conversation.messages.where('created_at < ?', message_queued_time).order(created_at: :asc).last(10)
    new_messages = @conversation.messages.where('created_at >= ?', message_queued_time)

    @messages = recap_messages + new_messages
    @messages = @messages.select(&:reportable?)

    mail(to: @contact&.email, reply_to: @agent&.email, subject: mail_subject(@messages.last))
  end

  private

  def mail_subject(last_message, trim_length = 50)
    subject_line = last_message&.content&.truncate(trim_length) || 'New messages on this conversation'
    "[##{@conversation.display_id}] #{subject_line}"
  end

  def reply_email
    if @conversation.account.domain_emails_enabled? && @conversation.account.domain.present?
      "reply+to+#{@conversation.uuid}@#{@conversation.account.domain}"
    else
      @agent&.email
    end
  end
end
