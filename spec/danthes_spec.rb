require "spec_helper"

describe Danthes do
  before(:each) do
    Danthes.startup
  end
  
  let(:config) { Danthes.config }

  it "defaults server to nil" do
    config[:server].should be_nil
  end

  it "defaults signature_expiration to nil" do
    config[:signature_expiration].should be_nil
  end

  it "defaults subscription timestamp to current time in milliseconds" do
    time = Time.now
    Time.stub!(:now).and_return(time)
    Danthes.subscription[:timestamp].should eq((time.to_f * 1000).round)
  end

  it "loads a simple configuration file via load_config" do
    Danthes.env = 'production'
    Danthes.load_config("spec/fixtures/danthes.yml")
    config[:server].should eq("http://example.com/faye")
    config[:secret_token].should eq("PRODUCTION_SECRET_TOKEN")
    config[:signature_expiration].should eq(600)
    config[:adapter].should eq('thin')
  end

  context "when redis config exists" do
    before do
      Danthes.env = 'test'
      Danthes.load_redis_config("spec/fixtures/danthes_redis.yml")
    end

    it "passes redis config to faye engine options" do
      config[:engine][:type].should eq Faye::Redis
      config[:engine][:host].should eq 'redis_host'
      config[:engine][:port].should eq 'redis_port'
      config[:engine][:password].should eq 'redis_password'
      config[:engine][:database].should eq 'redis_database'
      config[:engine][:namespace].should eq '/namespace'
    end

    it "should pass redis config and default options to faye" do
      Faye::RackAdapter.should_receive(:new) do |options|
        options[:engine].should eq Danthes.config[:engine]
        options[:mount].should eq '/faye'
      end
      Danthes.faye_app
    end
  end

  context "when redis config does not exist" do
    it "should not have :engine inside of config hash" do
      config.should_not include :engine
    end

    it "should have mount point" do
      config[:mount].should eq '/faye'
    end
  end

  it "raises an exception if an invalid environment is passed to load_config" do
    lambda {
      Danthes.load_config("spec/fixtures/danthes.yml", 'foo')
    }.should raise_error ArgumentError
  end

  it "includes channel, server, and custom time in subscription" do
    Danthes.config[:server] = "server"
    Danthes.config[:mount] = '/faye'
    subscription = Danthes.subscription(:timestamp => 123, :channel => "hello")
    subscription[:timestamp].should eq(123)
    subscription[:channel].should eq("hello")
    subscription[:server].should eq("server/faye")
  end
  
  it "returns full server url from server and mount configs" do
    Danthes.config[:server] = "server.com"
    Danthes.config[:mount] = '/faye'
    Danthes.server_url.should == 'server.com/faye'
  end

  it "does a sha1 digest of channel, timestamp, and secret token" do
    Danthes.config[:secret_token] = "token"
    subscription = Danthes.subscription(:timestamp => 123, :channel => "channel")
    subscription[:signature].should eq(Digest::SHA1.hexdigest("tokenchannel123"))
  end

  it "formats a message hash given a channel and a string for eval" do
    Danthes.config[:secret_token] = "token"
    Danthes.message("chan", "foo").should eq(
      :ext => {:danthes_token => "token"},
      :channel => "chan",
      :data => {
        :channel => "chan",
        :eval => "foo"
      }
    )
  end

  it "formats a message hash given a channel and a hash" do
    Danthes.config[:secret_token] = "token"
    Danthes.message("chan", :foo => "bar").should eq(
      :ext => {:danthes_token => "token"},
      :channel => "chan",
      :data => {
        :channel => "chan",
        :data => {:foo => "bar"}
      }
    )
  end

  it "publish message as json to server using Net::HTTP" do
    Danthes.config[:server] = "http://localhost"
    Danthes.config[:mount] = '/faye/path'
    message = 'foo'
    faye = stub_request(:post, "http://localhost/faye/path").
             with(:body => {"message"=>"\"foo\""},
                  :headers => {'Accept'=>'*/*', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Ruby'}).
             to_return(:status => 200, :body => "", :headers => {})
    Danthes.publish_message(message)
    faye.should have_been_made.once
  end

  it "it should use HTTPS if the server URL says so" do
    Danthes.config[:server] = "https://localhost"
    Danthes.config[:mount] = '/faye/path'
    http = mock(:http).as_null_object

    Net::HTTP.should_receive(:new).and_return(http)
    http.should_receive(:use_ssl=).with(true)

    Danthes.publish_message('foo')
  end

  it "it should not use HTTPS if the server URL says not to" do
    Danthes.config[:server] = "http://localhost"
    http = mock(:http).as_null_object

    Net::HTTP.should_receive(:new).and_return(http)
    http.should_receive(:use_ssl=).with(false)

    Danthes.publish_message('foo')
  end

  it "raises an exception if no server is specified when calling publish_message" do
    lambda {
      Danthes.publish_message("foo")
    }.should raise_error(Danthes::Error)
  end

  it "publish_to passes message to publish_message call" do
    Danthes.should_receive(:message).with("chan", "foo").and_return("message")
    Danthes.should_receive(:publish_message).with("message").and_return(:result)
    Danthes.publish_to("chan", "foo").should eq(:result)
  end

  it "has a Faye rack app instance" do
    Danthes.faye_app.should be_kind_of(Faye::RackAdapter)
  end

  it "says signature has expired when time passed in is greater than expiration" do
    Danthes.config[:signature_expiration] = 30*60
    time = Danthes.subscription[:timestamp] - 31*60*1000
    Danthes.signature_expired?(time).should be_true
  end

  it "says signature has not expired when time passed in is less than expiration" do
    Danthes.config[:signature_expiration] = 30*60
    time = Danthes.subscription[:timestamp] - 29*60*1000
    Danthes.signature_expired?(time).should be_false
  end

  it "says signature has not expired when expiration is nil" do
    Danthes.config[:signature_expiration] = nil
    Danthes.signature_expired?(0).should be_false
  end
end
