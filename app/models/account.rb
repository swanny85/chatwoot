# == Schema Information
#
# Table name: accounts
#
#  id             :integer          not null, primary key
#  domain         :string(100)
#  locale         :integer          default("en")
#  name           :string           not null
#  settings_flags :integer          default(0), not null
#  support_email  :string(100)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class Account < ApplicationRecord
  # used for single column multi flags
  include FlagShihTzu

  include Events::Types
  include Reportable

  DEFAULT_QUERY_SETTING = {
    flag_query_mode: :bit_operator
  }.freeze

  ACCOUNT_SETTINGS_FLAGS = {
    1 => :domain_emails_enabled
  }.freeze

  validates :name, presence: true

  has_many :account_users, dependent: :destroy
  has_many :agent_bot_inboxes, dependent: :destroy
  has_many :users, through: :account_users
  has_many :inboxes, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :contacts, dependent: :destroy
  has_many :facebook_pages, dependent: :destroy, class_name: '::Channel::FacebookPage'
  has_many :telegram_bots, dependent: :destroy
  has_many :twilio_sms, dependent: :destroy, class_name: '::Channel::TwilioSms'
  has_many :twitter_profiles, dependent: :destroy, class_name: '::Channel::TwitterProfile'
  has_many :web_widgets, dependent: :destroy, class_name: '::Channel::WebWidget'
  has_many :canned_responses, dependent: :destroy
  has_many :webhooks, dependent: :destroy
  has_one :subscription, dependent: :destroy
  has_many :notification_settings, dependent: :destroy
  has_flags ACCOUNT_SETTINGS_FLAGS.merge(column: 'settings_flags').merge(DEFAULT_QUERY_SETTING)

  enum locale: LANGUAGES_CONFIG.map { |key, val| [val[:iso_639_1_code], key] }.to_h

  after_create :create_subscription
  after_create :notify_creation
  after_destroy :notify_deletion

  def agents
    users.where(account_users: { role: :agent })
  end

  def administrators
    users.where(account_users: { role: :administrator })
  end

  def all_conversation_tags
    # returns array of tags
    conversation_ids = conversations.pluck(:id)
    ActsAsTaggableOn::Tagging.includes(:tag)
                             .where(context: 'labels',
                                    taggable_type: 'Conversation',
                                    taggable_id: conversation_ids)
                             .map { |_| _.tag.name }
  end

  def subscription_data
    agents_count = users.count
    per_agent_price = Plan.paid_plan.price
    {
      state: subscription.state,
      expiry: subscription.expiry.to_i,
      agents_count: agents_count,
      per_agent_cost: per_agent_price,
      total_cost: (per_agent_price * agents_count),
      iframe_url: Subscription::ChargebeeService.hosted_page_url(self),
      trial_expired: subscription.trial_expired?,
      account_suspended: subscription.suspended?,
      payment_source_added: subscription.payment_source_added
    }
  end

  def webhook_data
    {
      id: id,
      name: name
    }
  end

  private

  def create_subscription
    subscription = build_subscription
    subscription.save
  end

  def notify_creation
    Rails.configuration.dispatcher.dispatch(ACCOUNT_CREATED, Time.zone.now, account: self)
  end

  def notify_deletion
    Rails.configuration.dispatcher.dispatch(ACCOUNT_DESTROYED, Time.zone.now, account: self)
  end
end
