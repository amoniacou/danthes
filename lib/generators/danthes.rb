require 'rails/generators/base'

module Danthes
  module Generators
    class Base < Rails::Generators::Base
      def self.source_root
        File.dirname(__FILE__) + "/templates"
      end
      
      def self.banner
        "rails generate danthes:#{generator_name}"
      end
      
    private
      
      def add_gem(name, options = {})
        gemfile_path = File.join(destination_root, 'Gemfile')
        gemfile_content = File.read(gemfile_path)
        File.open(gemfile_path, 'a') { |f| f.write("\n") } unless gemfile_content =~ /\n\Z/
        gem name, options unless gemfile_content.include? name
      end

    end
  end
end
