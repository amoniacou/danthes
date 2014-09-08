require 'generators/danthes_generator'

module Danthes
  module Generators
    class InstallGenerator < Base
      desc 'Create sample config file and add rackup file'
      def copy_files
        template 'danthes.yml', 'config/danthes.yml'
        copy_file 'danthes.ru', 'danthes.ru'
      end
    end
  end
end
