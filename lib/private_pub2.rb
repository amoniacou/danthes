require 'digest/sha1'
require 'net/http'
require 'net/https'
require 'yajl/json_gem'

require 'private_pub2/faye_extension'
require 'private_pub2/engine' if defined? Rails

module PrivatePub
  class Error < StandardError; end

  class << self
    attr_reader :config
    attr_accessor :env
    
    # List of accepted options in config file
    ACCEPTED_KEYS = %w(adapter server secret_token mount signature_expiration timeout)
    
    # List of accepted options in redis config file
    REDIS_ACCEPTED_KEYS = %w(host port password database namespace socket)

    # Default options
    DEFAULT_OPTIONS = {:mount => "/faye", :timeout => 60, :extensions => [FayeExtension.new]}
    REDIS_DEFAULT_OPTIONS = {:type => Faye::Redis, :host => 'localhost', :port => 6379}
    
    # Resets the configuration to the default
    # Set environment
    def startup
      @config = DEFAULT_OPTIONS.dup
      @env = if defined? Rails
               Rails.env
             else
               ENV["RAILS_ENV"] || "development"
             end
    end
    
    # Loads the configuration from a given YAML file
    def load_config(filename)
      yaml = ::YAML.load_file(filename)[env]
      raise ArgumentError, "The #{environment} environment does not exist in #{filename}" if yaml.nil?
      (yaml.keys - ACCEPTED_KEYS).each {|k| yaml.delete(k)}
      yaml.each {|k, v| config[k.to_sym] = v}
    end

    # Loads the options from a given YAML file
    def load_redis_config(filename)
      require 'faye/redis'
      yaml = YAML.load_file(filename)[env]
      options = REDIS_DEFAULT_OPTIONS
      (yaml.keys - REDIS_ACCEPTED_KEYS).each {|k| yaml.delete(k)}
      yaml.each {|k, v| options[k.to_sym] = v}
      config[:engine] = options
    end

    # Publish the given data to a specific channel. This ends up sending
    # a Net::HTTP POST request to the Faye server.
    def publish_to(channel, data)
      publish_message(message(channel, data))
    end

    # Sends the given message hash to the Faye server using Net::HTTP.
    def publish_message(message)
      raise Error, "No server specified, ensure private_pub.yml was loaded properly." unless config[:server]
      url = URI.parse(config[:server])

      form = Net::HTTP::Post.new(url.path.empty? ? '/' : url.path)
      form.set_form_data(:message => message.to_json)

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = url.scheme == "https"
      http.start {|h| h.request(form)}
    end

    # Returns a message hash for sending to Faye
    def message(channel, data)
      message = {:channel => channel, :data => {:channel => channel}, :ext => {:private_pub_token => config[:secret_token]}}
      if data.kind_of? String
        message[:data][:eval] = data
      else
        message[:data][:data] = data
      end
      message
    end

    # Returns a subscription hash to pass to the PrivatePub.sign call in JavaScript.
    # Any options passed are merged to the hash.
    def subscription(options = {})
      sub = {:server => config[:server], :timestamp => (Time.now.to_f * 1000).round}.merge(options)
      sub[:signature] = Digest::SHA1.hexdigest([config[:secret_token], sub[:channel], sub[:timestamp]].join)
      sub
    end

    # Determine if the signature has expired given a timestamp.
    def signature_expired?(timestamp)
      timestamp < ((Time.now.to_f - config[:signature_expiration])*1000).round if config[:signature_expiration]
    end

    # Returns the Faye Rack application.
    def faye_app
      Faye::RackAdapter.new(config)
    end
  end

  startup
end
