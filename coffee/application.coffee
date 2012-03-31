define [
  'mediator',
  'controllers/session_controller', 'controllers/application_controller',
  'lib/router', 'routes'
], (mediator, SessionController, ApplicationController, Router, registerRoutes) ->
  'use strict'

  # The application bootstrapper.
  # In practise you might choose a more meaningful name.
  Application =
    initialize: ->
      @initControllers()
      @initRouter()

      # Freeze the object
      Object.freeze? @

      return

    # Instantiate meta-controllers
    initControllers: ->
      # Save the reference for testing introspection only.
      # Module should communicate with each other via Pub/Sub.
      @sessionController = new SessionController()
      @applicationController = new ApplicationController()

    # Instantiate the router
    initRouter: ->
      @router = new Router()

      # We have to make the router public because
      # the AppView needs to access it synchronously.
      mediator.setRouter @router

      # Register all routes declared in routes.coffee
      registerRoutes @router.match

      # After registering the routes, start Backbone.history
      @router.startHistory()

  Application