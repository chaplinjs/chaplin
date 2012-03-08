define ['lib/utils', 'lib/subscriber'], (utils, Subscriber) ->
  'use strict'

  class ServiceProvider
    # Mixin a Subscriber
    _(ServiceProvider.prototype).defaults Subscriber

    loading: false

    constructor: ->
      #console.debug 'ServiceProvider#constructor'

      # Mixin a Deferred
      _(this).extend $.Deferred()

      utils.deferMethods
        deferred: this
        methods: ['triggerLogin', 'getLoginStatus']
        onDeferral: @load

  ###

    Standard methods and their signatures:

    load: ->
      # Load a script like this:
      utils.loadLib 'http://example.org/foo.js', @loadHandler, @reject

    loadHandler: =>
      # Init the library, then resolve
      ServiceProviderLibrary.init(foo: 'bar')
      @resolve()

    isLoaded: ->
      # Return a Boolean
      Boolean window.ServiceProviderLibrary and ServiceProviderLibrary.login

    # Trigger login popup
    triggerLogin: (loginContext) ->
      callback = _(@loginHandler).bind(this, @loginHandler)
      ServiceProviderLibrary.login callback

    # Callback for the login popup
    loginHandler: (loginContext, response) =>

      if response
        # Publish successful login
        mediator.publish 'loginSuccessful',
          provider: this, loginContext: loginContext

        # Publish the session
        mediator.publish 'serviceProviderSession',
          provider: this
          userId: response.userId
          accessToken: response.accessToken
          # etc.

      else
        mediator.publish 'loginFail', provider: this, loginContext: loginContext

    getLoginStatus: (callback = @loginStatusHandler, force = false) ->
      ServiceProviderLibrary.getLoginStatus callback, force

    loginStatusHandler: (response) =>
      return unless response
      mediator.publish 'serviceProviderSession',
        provider: this
        userId: response.userId
        accessToken: response.accessToken
        # etc.

  ###