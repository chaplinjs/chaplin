define ['mediator', 'lib/utils', 'models/user', 'controllers/controller', 'lib/services/facebook', 'views/login_view'], (mediator, utils, User, Controller, Facebook, LoginView) ->

  'use strict'

  class SessionController extends Controller

    # Service provider instances as static properties
    # This just hardcoded here to avoid async loading of service providers.
    # In the end you might want to do this.
    @serviceProviders =
      facebook: new Facebook()

    # Was the login status already determined?
    loginStatusDetermined: false

    # This controller governs the LoginView
    loginView: null

    # Current service provider
    serviceProviderName: null

    initialize: ->
      #console.debug 'SessionController#initialize'

      # Login flow events
      @subscribeEvent 'loginAttempt', @loginAttempt
      @subscribeEvent 'serviceProviderSession', @serviceProviderSession

      # Handle login
      @subscribeEvent 'logout', @logout
      @subscribeEvent 'userData', @userData

      # Handler events which trigger an action

      # Show the login dialog
      @subscribeEvent '!showLogin', @showLoginView
      # Try to login with a service provider
      @subscribeEvent '!login', @triggerLogin
      # Initiate logout
      @subscribeEvent '!logout', @triggerLogout

      # Determine the logged-in state
      @getSession()


    # Load the JavaScript SDKs of all service providers

    loadSDKs: ->
      for name, serviceProvider of SessionController.serviceProviders
        serviceProvider.loadSDK()

    # Instantiate the user with the given data

    createUser: (userData) ->
      #console.debug 'SessinController#createUser', userData
      user = new User userData
      mediator.user = user


    # Try to get an existing session from one of the login providers

    getSession: ->
      #console.debug 'SessionController#getSession'
      @loadSDKs()
      for name, serviceProvider of SessionController.serviceProviders
        serviceProvider.done serviceProvider.getLoginStatus


    # Handler for the global !showLoginView event

    showLoginView: ->
      #console.debug 'SessionController#showLoginView'
      return if @loginView
      @loadSDKs()
      @loginView = new LoginView serviceProviders: SessionController.serviceProviders

    hideLoginView: ->
      #console.debug 'SessionController#hideLoginView'
      return unless @loginView
      @loginView.dispose()
      @loginView = null


    # Handler for the global !login event
    # Delegate the login to the selected service provider

    triggerLogin: (serviceProviderName) =>
      serviceProvider = SessionController.serviceProviders[serviceProviderName]
      #console.debug 'SessionController#triggerLogin', serviceProviderName, serviceProvider

      # Publish an event in case the provider SDK could not be loaded
      unless serviceProvider.isLoaded()
        mediator.publish 'serviceProviderMissing', serviceProviderName
        return

      # Publish a global loginAttempt event
      mediator.publish 'loginAttempt', serviceProviderName

      # Delegate to service provider
      serviceProvider.triggerLogin()


    # Handler for the global loginAttempt event

    loginAttempt: =>
      #console.debug 'SessionController#loginAttempt'


    # Handler for the global serviceProviderSession event

    serviceProviderSession: (session) =>
      # Save the session provider used for login
      @serviceProviderName = session.provider.name

      #console.debug 'SessionController#serviceProviderSession', session, @serviceProviderName

      # Hide the login view
      @hideLoginView()

      # Transform session into user attributes and create a user
      session.id = session.userId
      delete session.userId
      @createUser session

      @publishLogin()


    # Publish an event to notify all application components of the login

    publishLogin: ->
      #console.debug 'SessionController#publishLogin', mediator.user

      @loginStatusDetermined = true

      # Publish a global login event passing the user
      mediator.publish 'login', mediator.user
      mediator.publish 'loginStatus', true

    #
    # Logout
    #

    # Handler for the global !logout event

    triggerLogout: ->
      # Just publish a logout event for now
      mediator.publish 'logout'

    # Handler for the global logout event

    logout: =>
      #console.debug 'SessionController#logout'

      @loginStatusDetermined = true

      if mediator.user
        # Dispose the user model
        mediator.user.dispose()
        mediator.user = null

      # Discard the login info
      @serviceProviderName = null

      # Show the login view again
      @showLoginView()

      mediator.publish 'loginStatus', false

    #
    # Handler for the global userData event
    #

    userData: (data) ->
      #console.debug 'SessionController#userData', data
      mediator.user.set data

  # This controller has no custom dispose method since we expect it to
  # remain active during the whole application lifecycle.
