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
      #console.debug 'Facebook#constructor'

      utils.deferMethods
        deferred: this
        methods: ['parse', 'subscribe', 'postToGraph', 'getAccumulatedInfo', 'getInfo']
        onDeferral: @loadSDK

      # Bundle comment count calls into one request
      utils.wrapAccumulators this, ['getAccumulatedInfo']

      @subscribeEvent 'loginAbort', @loginAbort
      @subscribeEvent 'logout', @logout

    dispose: ->
      # TODO unsubscribe

    # Load the JavaScript SDK asynchronously

    loadSDK: ->
      #console.debug 'Facebook#loadSDK'

      return if @state() is 'resolved' or @loading
      @loading = true

      # Register load handler
      window.fbAsyncInit = @sdkLoadHandler

      # No success callback, there’s fbAsyncInit
      utils.loadLib 'http://connect.facebook.net/en_US/all.js', null, @reject

    # The main callback for the Facebook SDK

    sdkLoadHandler: =>
      #console.debug 'Facebook#sdkLoadHandler'

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
      #console.debug 'Facebook#sdkLoadHandler: resolve'
      @resolve()

    # Register handlers for several events

    registerHandlers: ->
      # Listen to logout on the Facebook
      @subscribe 'auth.logout', @facebookLogout
      # Listen to likes
      @subscribe 'edge.create', @processLike
      # Listen to comments
      @subscribe 'comment.create', @processComment

    # Check whether the Facebook SDK has been loaded

    isLoaded: ->
      Boolean window.FB and FB.login

    # Save the current login status and the access token
    # (if logged in and connected with app)

    saveAuthResponse: (response) =>
      #console.debug 'Facebook#saveAuthResponse', response
      @status = response.status
      authResponse = response.authResponse
      if authResponse
        @accessToken = authResponse.accessToken
      else
        @accessToken = null

    #
    # Get the Facebook login status, delegates to FB.getLoginStatus
    #
    # This actually determines a) whether the user is logged in at Facebook
    # and b) whether the user has authorized the app
    #

    getLoginStatus: (callback = @loginStatusHandler, force = false) =>
      #console.debug 'Facebook#getLoginStatus', @state()
      FB.getLoginStatus callback, force

    # Callback for the initial FB.getLoginStatus call

    loginStatusHandler: (response) =>
      #console.debug 'Facebook#loginStatusHandler', response
      @saveAuthResponse response
      authResponse = response.authResponse
      if authResponse
        @publishSession authResponse
        @getUserData()
      else
        mediator.publish 'logout'


    # Open the Facebook login popup
    # loginContext: object with context information where the user triggered the login
    #   Attributes:
    #   description - string
    #   model - optional model e.g. a topic the user wants to subscribe to

    triggerLogin: (loginContext) =>
      #console.debug 'Facebook#triggerLogin', loginContext
      FB.login _(@loginHandler).bind(@, loginContext), scope: scope

    # Callback for FB.login

    loginHandler: (loginContext, response) =>
      #console.debug 'Facebook#loginHandler', loginContext, response

      @saveAuthResponse response
      authResponse = response.authResponse

      if authResponse
        mediator.publish 'loginSuccessful', provider: this, loginContext: loginContext
        @publishSession authResponse
        @getUserData()

      else
        mediator.publish 'loginAbort', provider: this, loginContext: loginContext

        # Get the login status again (forced) because the user might be logged in anyway
        # This might happen when the user grants access to the app but closes
        # the second page of the auth dialog which asks for Extended Permissions.
        @getLoginStatus @publishAbortionResult, true


    # Publish the Facebook session

    publishSession: (authResponse) ->
      #console.debug 'Facebook#publishSession', authResponse
      mediator.publish 'serviceProviderSession',
        provider: this
        userId: authResponse.userID
        accessToken: authResponse.accessToken

    # Check login status after abort and publish success or failure

    publishAbortionResult: (response) =>
      @saveAuthResponse response
      authResponse = response.authResponse

      if authResponse
        mediator.publish 'loginSuccessful', provider: this, loginContext: loginContext
        mediator.publish 'loginSuccessfulThoughAborted', provider: this, loginContext: loginContext

        @publishSession authResponse

      else
        # Login failed ultimately
        mediator.publish 'loginFail', provider: this, loginContext: loginContext


    # Handler for the FB auth.logout event

    facebookLogout: (response) =>
      #console.debug 'Facebook#facebookLogout', response

      # The SDK fires bogus auth.logout events even when the user is logged in.
      # So just overwrite the current status.
      @saveAuthResponse response


    # Handler for the global logout event

    logout: ->
      # Clear the status properties
      @status = @accessToken = null

    #
    # Handlers for like and comment events
    #

    processLike: (url) =>
      #console.debug 'Facebook#processLike', url
      mediator.publish 'facebookLike', url

    processComment: (comment) =>
      #console.debug 'Facebook#processComment', comment, comment.href
      mediator.publish 'facebookComment', comment.href


    #
    # Parsing of Facebook social plugins
    #

    parse: (el) ->
      FB.XFBML.parse(el)


    #
    # Helper for subscribing to SDK events
    #

    subscribe: (eventType, handler) ->
      FB.Event.subscribe eventType, handler

    unsubscribe: (eventType, handler) ->
      FB.Event.unsubscribe eventType, handler

    #
    # Graph Querying
    #

    # Deferred wrapper for posting to the open graph

    postToGraph: (ogResource, data, callback) ->
      FB.api ogResource, 'post', data, (response) ->
        #console.debug 'Facebook#postToGraph callback', response
        callback response if callback

    # Post a message to the user’s stream

    postToStream: (data, callback) ->
      #console.debug 'Facebook.postToStream', data
      @postToGraph '/me/feed', data, callback

    # Get the info for the given URLs
    # Pass a string or an array of strings along with a callback function

    getAccumulatedInfo: (urls, callback) ->
      #console.debug 'Facebook#getAccumulatedInfo', urls, callback
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


    #
    # Fetch additional user data from Facebook (name, gender etc.)
    #

    getUserData: ->
      #console.debug 'Facebook#getUserData'
      @getInfo '/me', @processUserData

    processUserData: (response) =>
      #console.debug 'Facebook#processUserData', response
      mediator.publish 'userData', response
