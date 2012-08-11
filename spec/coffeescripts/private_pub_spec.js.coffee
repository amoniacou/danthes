describe "PrivatePub", ->
  window.Faye = undefined
  pub = undefined
  
  beforeEach ->
    pub = window.PrivatePub
    pub.fayeCallbacks = []
    pub.subscriptions = {}
    pub.subscriptionCallbacks = {}

  it "adds a subscription callback", ->
    pub.subscribe("hello", "callback")
    expect(pub.subscriptionCallbacks["hello"]).toEqual("callback")

  it "has a fayeExtension which adds matching subscription signature and timestamp to outgoing message", ->
    called = false
    message = {channel: "/meta/subscribe", subscription: "hello"}
    pub.subscriptions["hello"] = {signature: "abcd", timestamp: "1234"}
    pub.fayeExtension().outgoing message, (message) ->
      expect(message.ext.private_pub_signature).toEqual("abcd")
      expect(message.ext.private_pub_timestamp).toEqual("1234")
      called = true
    expect(called).toBeTruthy()

  it "evaluates javascript in message response", ->
    pub.handleResponse(eval: 'this.subscriptions.foo = "bar"')
    expect(pub.subscriptions.foo).toEqual("bar")

  it "triggers callback matching message channel in response", ->
    called = false
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
    pub.fayeClient = null
    pub.faye("callback")
    expect(pub.fayeCallbacks[0]).toEqual("callback")

  it "adds a script tag loading faye js when the server is present", ->
    client = {addExtension: jasmine.createSpy()}
    callback = jasmine.createSpy()
    pub.fayeClient = null
    window.Faye = null
    pub.subscriptions.server = "path/to/faye"
    pub.faye(callback)
    expect(pub.fayeCallbacks[0]).toEqual(callback)
    script = document.getElementById('faye-connection-script')
    expect(script).toBeDefined()
    expect(script.type).toEqual("text/javascript")
    expect(script.src).toMatch("path/to/faye.js")
  
  it "adds a faye subscription with response handler when signing", ->
    faye = {subscribe: jasmine.createSpy()}
    spyOn(pub, 'faye').andCallFake (callback) ->
      callback(faye)
    options = {server: "server", channel: "somechannel"}
    pub.fayeClient = 'string'
    pub.sign(options)
    expect(faye.subscribe).toHaveBeenCalled()
    expect(pub.subscriptions.server).toEqual("server")
    expect(pub.subscriptions.somechannel).toEqual(options)

  it "connects to faye server, adds extension, and executes callbacks", ->
    callback = jasmine.createSpy()
    client = {addExtension: jasmine.createSpy()}
    window.Faye = {}
    window.Faye.Client = (server) ->
      expect(server).toEqual("server")
      return client
    pub.subscriptions.server = "server"
    pub.fayeCallbacks.push(callback)
    spyOn(pub, 'fayeExtension')
    pub.connectToFaye()
    expect(pub.fayeClient).toEqual(client)
    expect(client.addExtension).toHaveBeenCalled()
    expect(pub.fayeExtension).toHaveBeenCalled()
    expect(callback).toHaveBeenCalledWith(client)