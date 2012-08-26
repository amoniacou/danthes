require 'generators/danthes'

module Danthes
  module Generators
    class InstallGenerator < Base
      desc 'Create sample config file and add rackup file'
      def copy_files
        template "danthes.yml", "config/danthes.yml"
        if ::Rails.version < "3.1"
          copy_file "../../../../app/assets/javascripts/danthes.js.coffee", "public/javascripts/danthes.js.coffee"
        end
        copy_file "danthes.ru", "danthes.ru"
      end
    end
  end
end
