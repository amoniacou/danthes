module Danthes
  module Generators
    class InstallGenerator < Rails::Generators::Base
      def self.source_root
        File.dirname(__FILE__) + "/templates"
      end

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
