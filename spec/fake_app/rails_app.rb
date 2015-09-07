ENV['RAILS_ENV'] ||= 'test'

require 'action_controller/railtie'
require 'danthes'

module RailsApp
  class Application < Rails::Application
    config.active_support.deprecation = :log
    config.cache_classes = true
    config.eager_load = false
    config.root = __dir__
    config.secret_token = 'x'*100
    config.session_store :cookie_store, key: '_myapp_session'
  end
end

Rails.backtrace_cleaner.remove_silencers!
RailsApp::Application.initialize!
