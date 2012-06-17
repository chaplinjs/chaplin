define [
  'backbone'
  'chaplin/mediator'
  'chaplin/dispatcher'
  'chaplin/views/layout'
  'chaplin/lib/router'
], (Backbone, mediator, Dispatcher, Layout, Router) ->
  'use strict'

  # The application bootstrapper
  # ----------------------------

  class Application

    # Borrow the static extend method from Backbone
    @extend = Backbone.Model.extend

    # The site title used in the document title
    title: ''

    # The application instantiates these three core modules
    dispatcher: null
    layout: null
    router: null

    initialize: ->

    initDispatcher: (options) ->
      @dispatcher = new Dispatcher options

    initLayout: (options = {}) ->
      options.title ?= @title
      @layout = new Layout options

    # Instantiate the dispatcher
    # --------------------------

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
      return if @disposed

      properties = ['dispatcher', 'layout', 'router']
      for prop in properties when this[prop]?
        this[prop].dispose()
        delete this[prop]

      @disposed = true

      # You’re frozen when your heart’s not open
      Object.freeze? this
