Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # set this to appropriate ingress channel when you are doing development in local with regards to incoming emails
  # config.action_mailbox.ingress = :sendgrid

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end
  config.public_file_server.enabled = true

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  config.active_job.queue_adapter = :sidekiq

  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }

  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = { host: 'localhost:3000' }

  # If you want to use letter opener instead of mailhog for testing emails locally,
  # uncomment the following line L49 and comment lines L51 through to L65
  # config.action_mailer.delivery_method = :letter_opener

  config.action_mailer.delivery_method = :smtp
  smtp_settings = {
    port: ENV['SMTP_PORT'] || 25,
    domain: ENV['SMTP_DOMAIN'] || 'localhost',
    address: ENV['SMTP_ADDRESS'] || 'chatwoot.com'
  }

  if ENV['SMTP_AUTHENTICATION'].present?
    smtp_settings[:user_name] = ENV['SMTP_USERNAME']
    smtp_settings[:password] = ENV['SMTP_PASSWORD']
    smtp_settings[:authentication] = ENV['SMTP_AUTHENTICATION']
    smtp_settings[:enable_starttls_auto] = ENV['SMTP_ENABLE_STARTTLS_AUTO'] if ENV['SMTP_ENABLE_STARTTLS_AUTO'].present?
  end

  config.action_mailer.smtp_settings = smtp_settings

  Rails.application.routes.default_url_options = { host: 'localhost', port: 3000 }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Disable host check during development
  config.hosts = nil

  # customize using the environment variables
  config.log_level = ENV.fetch('LOG_LEVEL', 'debug').to_sym

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  config.logger = ActiveSupport::Logger.new(Rails.root.join('log', Rails.env + '.log'), 1, ENV.fetch('LOG_SIZE', '1024').to_i.megabytes)

  # Bullet configuration to fix the N+1 queries
  config.after_initialize do
    Bullet.enable = true
    Bullet.bullet_logger = true
    Bullet.rails_logger = true
  end
end
