require 'spec_helper'

describe Danthes::FayeExtension do
  before(:each) do
    Danthes.startup
    @faye = Danthes::FayeExtension.new
    @message = { 'channel' => '/meta/subscribe', 'ext' => {} }
  end

  it 'adds an error on an incoming subscription with a bad signature' do
    @message['subscription'] = 'hello'
    @message['ext']['danthes_signature'] = 'bad'
    @message['ext']['danthes_timestamp'] = '123'
    message = @faye.incoming(@message, ->(m) { m })
    expect(message['error']).to eq('Incorrect signature.')
  end

  it 'has no error when the signature matches the subscription' do
    sub = Danthes.subscription(channel: 'hello')
    @message['subscription'] = sub[:channel]
    @message['ext']['danthes_signature'] = sub[:signature]
    @message['ext']['danthes_timestamp'] = sub[:timestamp]
    message = @faye.incoming(@message, ->(m) { m })
    expect(message['error']).to be_nil
  end

  it 'has an error when signature just expired' do
    Danthes.config[:signature_expiration] = 1
    sub = Danthes.subscription(timestamp: 123, channel: 'hello')
    @message['subscription'] = sub[:channel]
    @message['ext']['danthes_signature'] = sub[:signature]
    @message['ext']['danthes_timestamp'] = sub[:timestamp]
    message = @faye.incoming(@message, ->(m) { m })
    expect(message['error']).to eq('Signature has expired.')
  end

  it 'has an error when trying to publish to a custom channel with a bad token' do
    Danthes.config[:secret_token] = 'good'
    @message['channel'] = '/custom/channel'
    @message['ext']['danthes_token'] = 'bad'
    message = @faye.incoming(@message, ->(m) { m })
    expect(message['error']).to eq('Incorrect token.')
  end

  it 'raises an exception when attempting to call a custom channel without a secret_token set' do
    @message['channel'] = '/custom/channel'
    @message['ext']['danthes_token'] = 'bad'
    expect do
      message = @faye.incoming(@message, ->(m) { m })
    end.to raise_error('No secret_token config set, ensure danthes.yml is loaded properly.')
  end

  it 'has no error on other meta calls' do
    @message['channel'] = '/meta/connect'
    message = @faye.incoming(@message, ->(m) { m })
    expect(message['error']).to be_nil
  end

  it "should not let message carry the private pub token after server's validation" do
    Danthes.config[:secret_token] = 'good'
    @message['channel'] = '/custom/channel'
    @message['ext']['danthes_token'] = Danthes.config[:secret_token]
    message = @faye.incoming(@message, ->(m) { m })
    expect(message['ext']['danthes_token']).to be_nil
  end

end
