describe "Danthes", ->
  window.Faye = undefined
  pub = undefined

  signToChannel = (channel, addOptions = {}) ->
    sub = {callback: jasmine.createSpy(), errback: jasmine.createSpy()}
    faye = {subscribe: jasmine.createSpy().andReturn(sub)}
    spyOn(pub, 'faye').andCallFake (callback) ->
      callback(faye)
    options = {server: "server", channel: "#{channel}", timestamp: 1234567890, signature: '1234567890'}
    options['connect'] = addOptions['connect'] if addOptions['connect']?
    options['error'] = addOptions['error'] if addOptions['error']?
    pub.sign(options)
    return [faye, options]

  beforeEach ->
    pub = window.Danthes
    pub.reset()
    script = document.getElementById('faye-connection-script')
    if script?
      script.parentNode.removeChild(script)

  it "not adds a subscription callback without signing", ->
    expect(pub.subscribe("hello", "callback")).toBe(false)
    expect(pub.subscriptions).toEqual({})

  it "adds a subscription callback", ->
    signToChannel('hello')
    pub.subscribe("hello", "callback")
    expect(pub.subscriptions["hello"]['callback']).toEqual("callback")

  it "has a fayeExtension which adds matching subscription signature and timestamp to outgoing message", ->
    called = false
    message = {channel: "/meta/subscribe", subscription: "hello"}
    pub.subscriptions['hello'] = {}
    pub.subscriptions['hello']['opts'] = {signature: "abcd", timestamp: "1234"}
    pub.fayeExtension.outgoing message, (message) ->
      expect(message.ext.danthes_signature).toEqual("abcd")
      expect(message.ext.danthes_timestamp).toEqual("1234")
      called = true
    expect(called).toBeTruthy()

  it "evaluates javascript in message response", ->
    pub.handleResponse(eval: 'this.subscriptions.foo = "bar"')
    expect(pub.subscriptions.foo).toEqual("bar")

  it "triggers callback matching message channel in response", ->
    called = false
    signToChannel('test')
    pub.subscribe "test", (data, channel) ->
      expect(data).toEqual("abcd")
      expect(channel).toEqual("test")
      called = true
    pub.handleResponse(channel: "test", data: "abcd")
    expect(called).toBeTruthy()

  it "triggers faye callback function immediately when fayeClient is available", ->
    called = false
    pub.fayeClient = "faye"
    pub.faye (faye) ->
      expect(faye).toEqual("faye")
      called = true
    expect(called).toBeTruthy()

  it "adds fayeCallback when client and server aren't available", ->
    pub.faye("callback")
    expect(pub.fayeCallbacks[0]).toEqual("callback")

  it "adds a script tag loading faye js when the server is present", ->
    client = {addExtension: jasmine.createSpy()}
    callback = jasmine.createSpy()
    pub.server = "path/to/faye"
    pub.faye(callback)
    expect(pub.fayeCallbacks[0]).toEqual(callback)
    script = document.getElementById('faye-connection-script')
    expect(script).toBeDefined()
    expect(script.type).toEqual("text/javascript")
    expect(script.src).toMatch("path/to/faye/client.js")

  it "adds a signed channel to subscribe later", ->
    pub.fayeClient = 'string'
    [faye, options] = signToChannel('somechannel')
    expect(faye.subscribe).not.toHaveBeenCalled()
    expect(pub.subscriptions.somechannel.activated).toBeUndefined()
    expect(pub.subscriptions.somechannel).toBeDefined()
    expect(pub.subscriptions.somechannel.opts.signature).toEqual('1234567890')
    expect(pub.subscriptions.somechannel.opts.timestamp).toEqual(1234567890)
    expect(pub.subscriptions.somechannel.activated).toBeUndefined()

  it "adds a faye subscription with response handler when sign with connect option", ->
    pub.fayeClient = 'string'
    [faye, options] = signToChannel('somechannel', {'connect': jasmine.createSpy()})
    expect(faye.subscribe).toHaveBeenCalled()
    expect(pub.subscriptions.somechannel.activated).toBeDefined()

  it "adds a faye subscription with response handler when sign with error option", ->
    pub.fayeClient = 'string'
    [faye, options] = signToChannel('somechannel', {'error': jasmine.createSpy()})
    expect(faye.subscribe).toHaveBeenCalled()
    expect(pub.subscriptions.somechannel.activated).toBeDefined()

  it "adds a faye subscription with response handler when first time subscribing", ->
    pub.fayeClient = 'string'
    [faye, options] = signToChannel('somechannel')
    pub.subscribe('somechannel', ->)
    expect(faye.subscribe).toHaveBeenCalled()
    expect(pub.subscriptions.somechannel.activated).toBeDefined()

  it "connects to faye server, adds extension, and executes callbacks", ->
    callback = jasmine.createSpy()
    client = {addExtension: jasmine.createSpy()}
    window.Faye = {}
    window.Faye.Client = (server) ->
      expect(server).toEqual("server")
      return client
    pub.server = "server"
    pub.fayeCallbacks.push(callback)
    spyOn(pub, 'fayeExtension')
    pub.connectToFaye()
    expect(pub.fayeClient).toEqual(client)
    expect(client.addExtension).toHaveBeenCalledWith(pub.fayeExtension)
    expect(callback).toHaveBeenCalledWith(client)

  it "adds transport to disables", ->
    expect(pub.disableTransport('websocket')).toBeTruthy()
    expect(pub.disables).toEqual(['websocket'])

  it "adds transport to disables only one time", ->
    pub.disableTransport('websocket')
    pub.disableTransport('websocket')
    expect(pub.disables).toEqual(['websocket'])

  it "returns false if not accepted transport wants to be disabled", ->
    expect(pub.disableTransport('websocket123')).toBeUndefined()
    expect(pub.disables).toEqual([])

  it "connects to faye server, and executes disable once", ->
    callback = jasmine.createSpy()
    client = {addExtension: jasmine.createSpy(), disable: jasmine.createSpy()}
    window.Faye = {}
    window.Faye.Client = (server) -> client
    pub.server = "server"
    pub.disableTransport('websocket')
    pub.connectToFaye()
    expect(client.disable).toHaveBeenCalledWith('websocket')

  it "connects to faye server, and executes disable once", ->
    callback = jasmine.createSpy()
    client = {addExtension: jasmine.createSpy(), disable: jasmine.createSpy()}
    window.Faye = {}
    window.Faye.Client = (server) -> client
    pub.server = "server"
    pub.disableTransport('websocket')
    pub.disableTransport('long-polling')
    pub.connectToFaye()
    expect(client.disable).toHaveBeenCalledWith('websocket')
    expect(client.disable).toHaveBeenCalledWith('long-polling')

  it "adds subscription faye object into channel object", ->
    sub = {callback: jasmine.createSpy(), errback: jasmine.createSpy()}
    pub.fayeClient = {subscribe: jasmine.createSpy().andReturn(sub)}
    options = {server: "server", channel: 'somechannel'}
    pub.sign(options)
    pub.subscribe("somechannel", jasmine.createSpy())
    expect(sub.callback).toHaveBeenCalled()
    expect(sub.errback).toHaveBeenCalled()
    expect(pub.subscriptions.somechannel.sub).toEqual(sub)

  it "adds subscription faye object into channel object and call connect callback after connection", ->
    sub =
      callback: (f) ->
        f()
      errback: jasmine.createSpy()
    pub.fayeClient = {subscribe: jasmine.createSpy().andReturn(sub)}
    options = {server: "server", channel: 'somechannel'}
    pub.sign(options)
    connectSpy = jasmine.createSpy()
    pub.subscribe('somechannel', jasmine.createSpy(), connect: connectSpy)
    expect(connectSpy).toHaveBeenCalledWith(sub)

  it "adds subscription faye object into channel object and call error callback after connection", ->
    sub =
      callback: jasmine.createSpy()
      errback: (f) ->
        f('error')
    pub.fayeClient = {subscribe: jasmine.createSpy().andReturn(sub)}
    erroSpy = jasmine.createSpy()
    options = {server: "server", channel: 'somechannel'}
    pub.sign(options)
    pub.subscribe("somechannel", jasmine.createSpy(), error: erroSpy)
    expect(erroSpy).toHaveBeenCalledWith(sub, 'error')

  it "removes subscription to the channel", ->
    sub = {callback: jasmine.createSpy(), errback: jasmine.createSpy(), cancel: jasmine.createSpy()}
    pub.fayeClient = {subscribe: jasmine.createSpy().andReturn(sub)}
    options = {server: "server", channel: 'somechannel'}
    pub.sign(options)
    pub.subscribe('somechannel', jasmine.createSpy())
    pub.unsubscribe('somechannel')
    expect(sub.cancel).toHaveBeenCalled()
    expect(pub.subscriptions.somechannel.sub).toBeUndefined()

  it "removes all subscription to the channels", ->
    sub = {callback: jasmine.createSpy(), errback: jasmine.createSpy(), cancel: jasmine.createSpy()}
    pub.fayeClient = {subscribe: jasmine.createSpy().andReturn(sub)}
    options = {server: "server", channel: 'somechannel'}
    pub.sign(options)
    pub.subscribe "somechannel", jasmine.createSpy()
    pub.unsubscribeAll()
    expect(sub.cancel).toHaveBeenCalled()
    expect(pub.subscriptions.somechannel.sub).toBeUndefined()