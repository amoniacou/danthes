require 'danthes/view_helpers'

module Danthes
  class Engine < Rails::Engine
    # Loads the danthes.yml file if it exists.
    initializer 'danthes.config' do
      path = Rails.root.join('config/danthes.yml')
      ::Danthes.load_config(path) if path.exist?
    end

    # Adds the ViewHelpers into ActionView::Base
    initializer 'danthes.view_helpers' do
      ActionView::Base.send :include, ViewHelpers
    end
  end
end
