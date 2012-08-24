window.Danthes = class Danthes
  @debug: false    

  @debugMessage: (message) ->
    console.log(message) if @debug
  
  @reset: ->
    @connecting = false
    @fayeClient = null
    @fayeCallbacks = []
    @subscriptions = {}
    @server = null
    @disables = []
    @connectionSettings =
      timeout: 120
      retry: 5
      endpoints: {}

  @faye: (callback) =>
    if @fayeClient?
      callback(@fayeClient)
    else
      @fayeCallbacks.push(callback)
      if @server && !@connecting
        @connecting = true
        unless Faye?
          script = document.createElement 'script'
          script.type = 'text/javascript'
          script.src = "#{@server}/client.js"
          script.id = "faye-connection-script"
          complete = false
          script.onload = script.onreadystatechange = () =>
            if !complete && (!this.readyState || this.readyState is "loaded" || this.readyState is "complete")
              complete = true
              script.onload = script.onreadystatechange = null
              @debugMessage 'connect to faye after script loaded'
              @connectToFaye()
          @debugMessage 'faye script init'
          document.documentElement.appendChild script
      else
        @debugMessage 'faye already inited'
        @connectToFaye()
  
  @fayeExtension:
    incoming : (message, callback) =>
      @debugMessage "incomming message #{message}"
      callback(message)
    outgoing : (message, callback) =>
      @debugMessage "outgoing message #{message}"
      if message.channel == "/meta/subscribe"
        subscription = @subscriptions[message.subscription]['opts']
        # Attach the signature and timestamp to subscription messages
        message.ext = {} unless message.ext?
        message.ext.danthes_signature = subscription.signature
        message.ext.danthes_timestamp = subscription.timestamp
      callback(message)

  @connectToFaye: ->
    if @server && Faye?
      @debugMessage 'trying to connect faye'
      @fayeClient = new Faye.Client(@server, @connectionSettings)
      @fayeClient.addExtension(@fayeExtension)
      # Disable any features what we want
      @fayeClient.disable(key) for key in @disables
      @debugMessage 'faye connected'
      callback(@fayeClient) for callback in @fayeCallbacks

  @sign: (options) ->
    @debugMessage 'sign to faye'
    @server = options.server unless @server
    channel = options.channel
    unless @subscriptions[channel]?
      @subscriptions[channel] = {}
      @subscriptions[channel]['opts'] = options
      @faye (faye) =>
        subscription = faye.subscribe channel, (message) =>
          @handleResponse(message)
        if subscription?
          @subscriptions[channel]['sub'] = subscription
          subscription.callback =>
            @debugMessage "subscription for #{channel} is active now"
          subscription.errback (error) =>
            @debugMessage "error for #{channel}: #{error.message}"

  @handleResponse: (message) ->
    if message.eval
      eval(message.eval)
    channel = message.channel
    return unless @subscriptions[channel]?
    if callback = @subscriptions[channel]['callback']
      callback(message.data, channel)
      
  @subscribe: (channel, callback) ->
    @debugMessage "subscribing to #{channel}"
    if @subscriptions[channel]?
      # Changing callback on every call
      @subscriptions[channel]['callback'] = callback
    else
      @debugMessage "Cannot subscribe on channel '#{channel}'. You need sign to channel first."
      return false
    true
  
  @unsubscribe: (channel) ->
    @debugMessage "unsubscribing from #{channel}"
    if @subscriptions[channel]
      @subscriptions[channel]['sub'].cancel()
      delete @subscriptions[channel]
  
  @unsubscribeAll: ->
    @unsubscribe(channel) for channel, _ of @subscriptions

window.Danthes.reset()