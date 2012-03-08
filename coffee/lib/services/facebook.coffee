define [
  'mediator', 'lib/utils', 'lib/services/service_provider'
], (mediator, utils, ServiceProvider) ->
  'use strict'

  class Facebook extends ServiceProvider
    # Note: This is the app ID for an example Facebook app.
    # You might change this to your own application ID.
    facebookAppId = '115149731946795'

    # The permissions we’re asking for.
    # See https://developers.facebook.com/docs/reference/api/permissions/
    # We want to read the user’s likes, that’s all.
    scope = 'user_likes'

    name: 'facebook'

    # Login status at Facebook
    status: null

    # The current session API access token
    accessToken: null

    constructor: ->
      super

      utils.deferMethods
        deferred: this
        methods: [
          'parse', 'subscribe', 'postToGraph', 'getAccumulatedInfo', 'getInfo'
        ]
        onDeferral: @load

      # Bundle comment count calls into one request
      utils.wrapAccumulators this, ['getAccumulatedInfo']

      @subscribeEvent 'loginAbort', @loginAbort
      @subscribeEvent 'logout', @logout

    dispose: ->
      # TODO unsubscribe

    # Load the JavaScript library asynchronously
    load: ->
      return if @state() is 'resolved' or @loading
      @loading = true

      # Register load handler
      window.fbAsyncInit = @loadHandler

      # No success callback, there’s fbAsyncInit
      utils.loadLib 'http://connect.facebook.net/en_US/all.js', null, @reject

    # The main callback for the Facebook library
    loadHandler: =>
      @loading = false
      try
        # IE 8 throws an exception
        delete window.fbAsyncInit
      catch error
        window.fbAsyncInit = undefined

      FB.init
        appId:  facebookAppId
        status: true
        cookie: true
        xfbml:  false

      @registerHandlers()

      # Resolve the Deferred
      @resolve()

    # Register handlers for several events
    registerHandlers: ->
      # Listen to logout on the Facebook
      @subscribe 'auth.logout', @facebookLogout
      # Listen to likes
      @subscribe 'edge.create', @processLike
      # Listen to comments
      @subscribe 'comment.create', @processComment

    # Check whether the Facebook library has been loaded
    isLoaded: ->
      Boolean window.FB and FB.login

    # Save the current login status and the access token
    # (if logged in and connected with app)
    saveAuthResponse: (response) =>
      @status = response.status
      authResponse = response.authResponse
      if authResponse
        @accessToken = authResponse.accessToken
      else
        @accessToken = null

    # Get the Facebook login status, delegates to FB.getLoginStatus
    #
    # This actually determines a) whether the user is logged in at Facebook
    # and b) whether the user has authorized the app
    getLoginStatus: (callback = @loginStatusHandler, force = false) =>
      FB.getLoginStatus callback, force

    # Callback for the initial FB.getLoginStatus call
    loginStatusHandler: (response) =>
      @saveAuthResponse response
      authResponse = response.authResponse
      if authResponse
        @publishSession authResponse
        @getUserData()
      else
        mediator.publish 'logout'

    # Open the Facebook login popup
    # loginContext: object with context information where the
    # user triggered the login
    #   Attributes:
    #   description - string
    #   model - optional model e.g. a topic the user wants to subscribe to
    triggerLogin: (loginContext) =>
      FB.login _(@loginHandler).bind(this, loginContext), {scope}

    # Callback for FB.login
    loginHandler: (loginContext, response) =>
      @saveAuthResponse response
      authResponse = response.authResponse

      if authResponse
        mediator.publish 'loginSuccessful', {provider: this, loginContext}
        @publishSession authResponse
        @getUserData()

      else
        mediator.publish 'loginAbort', {provider: this, loginContext}

        # Get the login status again (forced) because the user might be
        # logged in anyway. This might happen when the user grants access
        # to the app but closes the second page of the auth dialog which
        # asks for Extended Permissions.
        @getLoginStatus @publishAbortionResult, true

    # Publish the Facebook session
    publishSession: (authResponse) ->
      mediator.publish 'serviceProviderSession',
        provider: this
        userId: authResponse.userID
        accessToken: authResponse.accessToken

    # Check login status after abort and publish success or failure
    publishAbortionResult: (response) =>
      @saveAuthResponse response
      authResponse = response.authResponse

      if authResponse
        mediator.publish 'loginSuccessful', {provider: this, loginContext}
        mediator.publish 'loginSuccessfulThoughAborted', {
          provider: this, loginContext
        }

        @publishSession authResponse

      else
        # Login failed ultimately
        mediator.publish 'loginFail', {provider: this, loginContext}

    # Handler for the FB auth.logout event
    facebookLogout: (response) =>
      # The Facebook library fires bogus auth.logout events even when the user
      # is logged in. So just overwrite the current status.
      @saveAuthResponse response

    # Handler for the global logout event
    logout: ->
      # Clear the status properties
      @status = @accessToken = null

    # Handlers for like and comment events
    # ------------------------------------
    processLike: (url) =>
      mediator.publish 'facebookLike', url

    processComment: (comment) =>
      mediator.publish 'facebookComment', comment.href

    # Parsing of Facebook social plugins
    # ----------------------------------

    parse: (el) ->
      FB.XFBML.parse(el)

    # Helper for subscribing to Facebook events
    # -----------------------------------------

    subscribe: (eventType, handler) ->
      FB.Event.subscribe eventType, handler

    unsubscribe: (eventType, handler) ->
      FB.Event.unsubscribe eventType, handler

    # Graph Querying
    # --------------

    # Deferred wrapper for posting to the open graph
    postToGraph: (ogResource, data, callback) ->
      FB.api ogResource, 'post', data, (response) ->
        callback response if callback

    # Post a message to the user’s stream
    postToStream: (data, callback) ->
      @postToGraph '/me/feed', data, callback

    # Get the info for the given URLs
    # Pass a string or an array of strings along with a callback function
    getAccumulatedInfo: (urls, callback) ->
      urls = [urls] if typeof urls == 'string'
      # Reduce to a comma-separated, string to embed into the query string
      urls = _(urls).reduce((memo, url) ->
        memo += ',' if memo
        memo += encodeURIComponent(url)
      , '')
      FB.api "?ids=#{urls}", callback

    # Get information for node in the FB graph
    # `id` might be a FB node ID or a normal URL
    getInfo: (id, callback) ->
      FB.api id, callback

    # Fetch additional user data from Facebook (name, gender etc.)
    # ------------------------------------------------------------

    getUserData: ->
      @getInfo '/me', @processUserData

    processUserData: (response) =>
      mediator.publish 'userData', response
