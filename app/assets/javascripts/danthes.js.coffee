# Danthes Privat pub/sub Faye wrapper
#
# @example Howto enable debug
#   Danthes.debug = true
# @example reset all internal data
#   Danthes.reset()
# @example Howto sign and subscribe on channel with callback function
#   Danthes.sign
#     server: 'faye.example.com'
#     channel: 'somechannel'
#     signature: 'dc1c71d3e959ebb6f49aa6af0c86304a0740088d'
#     timestamp: 1302306682972
#     connect: (subscription) ->
#       console.log(subscription)
#     error: (subscription, error) ->
#       console.log("error: #{error}")

window.Danthes = class Danthes

  @debug: false

  @debugMessage: (message) ->
    console.log(message) if @debug

  # Reset all
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

  # Connect to faye
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
            if !complete && (!script.readyState || script.readyState is "loaded" || script.readyState is "complete")
              complete = true
              script.onload = script.onreadystatechange = null
              @debugMessage 'connect to faye after script loaded'
              @connectToFaye()
          @debugMessage 'faye script init'
          document.documentElement.appendChild script
      else
        @debugMessage 'faye already inited'
        @connectToFaye()

  # Faye extension for incoming and outgoing messages
  @fayeExtension:
    incoming : (message, callback) =>
      @debugMessage "incomming message #{JSON.stringify(message)}"
      callback(message)
    outgoing : (message, callback) =>
      @debugMessage "outgoing message #{JSON.stringify(message)}"
      if message.channel == "/meta/subscribe"
        subscription = @subscriptions[message.subscription]['opts']
        # Attach the signature and timestamp to subscription messages
        message.ext = {} unless message.ext?
        message.ext.danthes_signature = subscription.signature
        message.ext.danthes_timestamp = subscription.timestamp
      callback(message)

  # Initialize Faye client
  @connectToFaye: ->
    if @server && Faye?
      @debugMessage 'trying to connect faye'
      @fayeClient = new Faye.Client(@server, @connectionSettings)
      @fayeClient.addExtension(@fayeExtension)
      # Disable any features what we want
      @fayeClient.disable(key) for key in @disables
      @debugMessage 'faye connected'
      callback(@fayeClient) for callback in @fayeCallbacks

  # Sign to channel
  # @param [Object] options for signing
  @sign: (options) ->
    @debugMessage 'sign to faye'
    @server = options.server unless @server
    channel = options.channel
    unless @subscriptions[channel]?
      @subscriptions[channel] = {}
      @subscriptions[channel]['callback'] = options['callback'] if options['callback']?
      @subscriptions[channel]['opts'] =
        signature: options['signature']
        timestamp: options['timestamp']
      # If we have 'connect' or 'error' option then force channel activation
      if options['connect']? || options['error']?
        @activateChannel channel, options

  # Activating channel subscription
  # @param channel [String] channel name
  # @param options [Object] subscription callback options
  @activateChannel: (channel, options = {}) ->
    return true if @subscriptions[channel]['activated']
    @faye (faye) =>
      subscription = faye.subscribe channel, (message) => @handleResponse(message)
      if subscription?
        @subscriptions[channel]['sub'] = subscription
        subscription.callback =>
          options['connect']?(subscription)
          @debugMessage "subscription for #{channel} is active now"
        subscription.errback (error) =>
          options['error']?(subscription, error)
          @debugMessage "error for #{channel}: #{error.message}"
        @subscriptions[channel]['activated'] = true

  # Handle response from Faye
  # @param [Object] message from Faye
  @handleResponse: (message) ->
    if message.eval
      eval(message.eval)
    channel = message.channel
    return unless @subscriptions[channel]?
    if callback = @subscriptions[channel]['callback']
      callback(message.data, channel)

  # Disable transports
  # @param [String] name of transport
  @disableTransport: (transport) ->
    return unless transport in ['websocket', 'long-polling', 'callback-polling', 'in-process']
    unless transport in @disables
      @disables.push(transport)
      @debugMessage "#{transport} faye transport will be disabled"
    true

  # Subscribe to channel with callback
  # @param channel [String] Channel name
  # @param callback [Function] Callback function
  # @param options [Object] subscription callbacks options
  @subscribe: (channel, callback, options = {}) ->
    @debugMessage "subscribing to #{channel}"
    if @subscriptions[channel]?
      @activateChannel(channel, options)
      # Changing callback on every call
      @subscriptions[channel]['callback'] = callback
    else
      @debugMessage "Cannot subscribe on channel '#{channel}'. You need sign to channel first."
      return false
    true

  # Unsubscribe from channel
  # @param [String] Channel name
  # @param [Boolean] Full unsubscribe
  @unsubscribe: (channel, fullUnsubscribe = false) ->
    @debugMessage "unsubscribing from #{channel}"
    if @subscriptions[channel] && @subscriptions[channel]['activated']
      @subscriptions[channel]['sub'].cancel()
      if fullUnsubscribe
        delete @subscriptions[channel]
      else
        delete @subscriptions[channel]['activated']
        delete @subscriptions[channel]['sub']

  # Unsubscribe from all channels
  @unsubscribeAll: ->
    @unsubscribe(channel) for channel, _ of @subscriptions

window.Danthes.reset()