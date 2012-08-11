window.PrivatePub = class PrivatePub
  @connecting: false
  @debug: false
  @fayeClient: null
  @fayeCallbacks: []
  @subscriptions: {}
  @subscriptionCallbacks: {}

  @debugMessage: (message) ->
    console.log(message) if @debug
  
  @faye: (callback) =>
    if @fayeClient?
      callback(@fayeClient)
    else
      @fayeCallbacks.push(callback)
      if @subscriptions.server && !@connecting
        @connecting = true
        console.log Faye?
        console.log window.Faye?
        console.log document
        unless Faye?
          script = document.createElement 'script'
          script.type = 'text/javascript'
          script.src = @subscriptions.server + '.js'
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
  
  @fayeExtension: ->
    outgoing : (message, callback) =>
      if message.channel == "/meta/subscribe"
        subscription = @subscriptions[message.subscription]
        # Attach the signature and timestamp to subscription messages
        message.ext = {} if !message.ext
        message.ext.private_pub_signature = subscription.signature
        message.ext.private_pub_timestamp = subscription.timestamp
      callback(message)

  @connectToFaye: ->
    if @subscriptions.server && Faye?
      @debugMessage 'trying to connect faye'
      @fayeClient = new Faye.Client(@subscriptions.server)
      @fayeClient.addExtension(@fayeExtension())
      @debugMessage 'faye connected'
      for callback in @fayeCallbacks
        callback(@fayeClient)

  @sign: (options) ->
    @debugMessage 'sign to faye'
    unless @subscriptions.server
      @subscriptions.server = options.server
    unless @subscriptions[options.channel]
      @subscriptions[options.channel] = options
      @faye (faye) =>
        subscription = faye.subscribe options.channel, (message) =>
          @handleResponse(message)
        if subscription?  
          subscription.callback =>
            @debugMessage 'subscription for ' + options.channel + ' is active now'
          subscription.errback (error) =>
            @debugMessage 'error for ' + options.channel + ': ' + error.message

  @handleResponse: (message) ->
    if message.eval
      eval(message.eval)
    if callback = @subscriptionCallbacks[message.channel]
      callback(message.data, message.channel)
      
  @subscribe: (channel, callback) ->
    @debugMessage 'subscribing to ' + channel
    # Changing callback on every call
    @subscriptionCallbacks[channel] = callback
  
  @unsubscribe: (channel) ->
    @debugMessage 'unsubscribing from ' + channel
    if @subscriptionCallbacks[channel]
      @subscriptionCallbacks[channel] = null
      @faye (faye) =>
        faye.unsubscribe channel
      
