define ['mediator', 'controllers/session_controller', 'controllers/application_controller', 'lib/router'], (mediator, SessionController, ApplicationController, Router) ->

  'use strict'

  Application =

    initialize: ->
      @startupControllers()
      @startupRouter()

    startupControllers: ->
      sessionController = new SessionController()
      sessionController.startup()

      applicationController = new ApplicationController()
      applicationController.startup()

    startupRouter: ->
      # We have to make the router public because
      # the AppView needs to access it synchronously
      mediator.router = new Router()

      # Make router property readonly
      Object.defineProperty? mediator, 'router', writable: false

  Application.initialize()

  Application