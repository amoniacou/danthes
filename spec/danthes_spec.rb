require 'spec_helper'

describe Danthes do
  before(:each) do
    Danthes.startup
  end

  let(:config) { Danthes.config }

  it 'defaults server to nil' do
    expect(config[:server]).to be_nil
  end

  it 'defaults signature_expiration to nil' do
    expect(config[:signature_expiration]).to be_nil
  end

  it 'defaults subscription timestamp to current time in milliseconds' do
    time = Time.now
    allow(Time).to receive(:now).and_return(time)
    expect(Danthes.subscription[:timestamp]).to eq((time.to_f * 1000).round)
  end

  it 'loads a simple configuration file via load_config' do
    Danthes.env = 'production'
    Danthes.load_config('spec/fixtures/danthes.yml')
    expect(config[:server]).to eq('http://example.com/faye')
    expect(config[:secret_token]).to eq('PRODUCTION_SECRET_TOKEN')
    expect(config[:signature_expiration]).to eq(600)
    expect(config[:adapter]).to eq('thin')
  end

  it 'loads configuration file with erb via load_config' do
    ENV['DANTHES_SERVER'] = 'http://example.com'
    Danthes.env = 'production'
    Danthes.load_config('spec/fixtures/danthes_with_erb.yml')
    expect(config[:server]).to eq('http://example.com')
  end

  context 'when redis config exists' do
    before do
      Danthes.env = 'test'
      Danthes.load_redis_config('spec/fixtures/danthes_redis.yml')
    end

    it 'passes redis config to faye engine options' do
      expect(config[:engine][:type]).to eq Faye::Redis
      expect(config[:engine][:host]).to eq 'redis_host'
      expect(config[:engine][:port]).to eq 'redis_port'
      expect(config[:engine][:password]).to eq 'redis_password'
      expect(config[:engine][:database]).to eq 'redis_database'
      expect(config[:engine][:namespace]).to eq '/namespace'
    end

    it 'should pass redis config and default options to faye' do
      expect(Faye::RackAdapter).to receive(:new) do |options|
        expect(options[:engine]).to eq Danthes.config[:engine]
        expect(options[:mount]).to eq '/faye'
      end
      Danthes.faye_app
    end
  end

  context 'when redis config does not exist' do
    it 'should not have :engine inside of config hash' do
      expect(config).not_to include :engine
    end

    it 'should have mount point' do
      expect(config[:mount]).to eq '/faye'
    end
  end

  it 'raises an exception if an invalid environment is passed to load_config' do
    expect do
      Danthes.load_config('spec/fixtures/danthes.yml', 'foo')
    end.to raise_error ArgumentError
  end

  it 'includes channel, server, and custom time in subscription' do
    Danthes.config[:server] = 'server'
    Danthes.config[:mount] = '/faye'
    subscription = Danthes.subscription(timestamp: 123, channel: 'hello')
    expect(subscription[:timestamp]).to eq(123)
    expect(subscription[:channel]).to eq('hello')
    expect(subscription[:server]).to eq('server/faye')
  end

  it 'returns full server url from server and mount configs' do
    Danthes.config[:server] = 'server.com'
    Danthes.config[:mount] = '/faye'
    expect(Danthes.server_url).to eq('server.com/faye')
  end

  it 'does a sha1 digest of channel, timestamp, and secret token' do
    Danthes.config[:secret_token] = 'token'
    subscription = Danthes.subscription(timestamp: 123, channel: 'channel')
    expect(subscription[:signature]).to eq(Digest::SHA1.hexdigest('tokenchannel123'))
  end

  it 'formats a message hash given a channel and a string for eval' do
    Danthes.config[:secret_token] = 'token'
    expect(Danthes.message('chan', 'foo')).to eq(
      ext: { danthes_token: 'token' },
      channel: 'chan',
      data: {
        channel: 'chan',
        eval: 'foo'
      }
    )
  end

  it 'formats a message hash given a channel and a hash' do
    Danthes.config[:secret_token] = 'token'
    expect(Danthes.message('chan', foo: 'bar')).to eq(
      ext: { danthes_token: 'token' },
      channel: 'chan',
      data: {
        channel: 'chan',
        data: { foo: 'bar' }
      }
    )
  end

  it 'publish message as json to server using Net::HTTP' do
    Danthes.config[:server] = 'http://localhost'
    Danthes.config[:mount] = '/faye/path'
    message = 'foo'
    faye = stub_request(:post, 'http://localhost/faye/path').
             with(body: { 'message' => "\"foo\"" },
                  headers: { 'Accept' => '*/*', 'Content-Type' => 'application/x-www-form-urlencoded', 'User-Agent' => 'Ruby' }).
             to_return(status: 200, body: '', headers: {})
    Danthes.publish_message(message)
    expect(faye).to have_been_made.once
  end

  it 'it should use HTTPS if the server URL says so' do
    Danthes.config[:server] = 'https://localhost'
    Danthes.config[:mount] = '/faye/path'
    http = double(:http).as_null_object

    expect(Net::HTTP).to receive(:new).and_return(http)
    expect(http).to receive(:use_ssl=).with(true)

    Danthes.publish_message('foo')
  end

  it 'it should not use HTTPS if the server URL says not to' do
    Danthes.config[:server] = 'http://localhost'
    http = double(:http).as_null_object

    expect(Net::HTTP).to receive(:new).and_return(http)
    expect(http).to receive(:use_ssl=).with(false)

    Danthes.publish_message('foo')
  end

  it 'raises an exception if no server is specified when calling publish_message' do
    expect do
      Danthes.publish_message('foo')
    end.to raise_error(Danthes::Error)
  end

  it 'publish_to passes message to publish_message call' do
    expect(Danthes).to receive(:message).with('chan', 'foo').and_return('message')
    expect(Danthes).to receive(:publish_message).with('message').and_return(:result)
    expect(Danthes.publish_to('chan', 'foo')).to eq(:result)
  end

  it 'has a Faye rack app instance' do
    expect(Danthes.faye_app).to be_kind_of(Faye::RackAdapter)
  end

  it 'says signature has expired when time passed in is greater than expiration' do
    Danthes.config[:signature_expiration] = 30 * 60
    time = Danthes.subscription[:timestamp] - 31 * 60 * 1000
    expect(Danthes.signature_expired?(time)).to be_truthy
  end

  it 'says signature has not expired when time passed in is less than expiration' do
    Danthes.config[:signature_expiration] = 30 * 60
    time = Danthes.subscription[:timestamp] - 29 * 60 * 1000
    expect(Danthes.signature_expired?(time)).to be_falsy
  end

  it 'says signature has not expired when expiration is nil' do
    Danthes.config[:signature_expiration] = nil
    expect(Danthes.signature_expired?(0)).to be_falsy
  end
end
