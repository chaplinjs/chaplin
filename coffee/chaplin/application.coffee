define [
  'mediator',
  'chaplin/controllers/application_controller',
  'chaplin/views/application_view',
  'chaplin/lib/router'
], (mediator, ApplicationController, ApplicationView, Router) ->
  'use strict'

  # The application bootstrapper
  # ----------------------------

  class Application

    # The site title used in the document title
    title: ''

    # The application instantiates these three core modules
    applicationController: null
    applicationView: null
    router: null

    initialize: ->
      ###console.debug 'Application#initialize'###

      # Instantiate the AppController and AppView
      # -----------------------------------------

      # Save the references for testing introspection only.
      # Module should communicate with each other via Pub/Sub.
      @applicationController = new ApplicationController()
      @applicationView = new ApplicationView title: @title

    # Instantiate the router
    # ----------------------

    # Pass the function typically returned by routes.coffee
    initRouter: (routes, options) ->
      # Save the reference for testing introspection only.
      # Modules should communicate with each other via Pub/Sub.
      @router = new Router options

      # Register all routes declared in routes.coffee
      routes? @router.match

      # After registering the routes, start Backbone.history
      @router.startHistory()

    # Disposal
    # --------

    disposed: false

    dispose: ->
      ###console.debug 'Application#dispose'###
      return if @disposed

      properties = ['applicationController', 'applicationView', 'router']
      for prop in properties
        this[prop].dispose()
        delete this[prop]

      @disposed = true

      # Your're frozen when your heart’s not open
      Object.freeze? this
