# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :cookie_store,
  key: '_nua-messaging_session',
  secure: Rails.env.production?, # HTTPS in production
  same_site: :lax, # Improve session isolation between windows
  expire_after: 24.hours # Session timeout for better security
