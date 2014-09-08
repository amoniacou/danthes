require 'generators/danthes'

module Danthes
  module Generators
    class RedisInstallGenerator < Base
      desc 'Create sample redis config file and add faye-redis gem to Gemfile'

      def copy_files
        template 'danthes_redis.yml', 'config/danthes_redis.yml'
      end

      def add_redis_gem
        add_gem 'faye-redis'
      end
    end
  end
end
