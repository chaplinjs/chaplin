define ['mediator', 'controllers/session_controller', 'controllers/application_controller', 'lib/router'], (mediator, SessionController, ApplicationController, Router) ->

  'use strict'

  # The application bootstrapper.
  # In practise you might choose a more meaningful name.
  Application =

    initialize: ->
      @initControllers()
      @initRouter()
      return

    # Instantiate meta-controllers
    initControllers: ->
      # At the moment, do not save the references.
      # They might be safed as instance properties or directly on the mediator.
      # Normally, controllers can communicate with each other via Pub/Sub.
      new SessionController()
      new ApplicationController()

    # Instantiate the router
    initRouter: ->
      # We have to make the router public because
      # the AppView needs to access it synchronously.
      mediator.router = new Router()

      # Make router property readonly
      Object.defineProperty? mediator, 'router', writable: false

  # Freeze the object
  Object.freeze? Application

  Application