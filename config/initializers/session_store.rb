# Session configuration for Rails 8
# This ensures proper session management with Turbo and Devise

Rails.application.config.session_store :cookie_store, 
  key: '_chrit_session',
  expire_after: 2.weeks,
  secure: Rails.env.production?,
  same_site: :lax,
  httponly: true