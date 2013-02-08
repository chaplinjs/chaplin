'use strict'

_ = require 'underscore'
Backbone = require 'backbone'
Dispatcher = require 'chaplin/dispatcher'
Layout = require 'chaplin/views/layout'
Router = require 'chaplin/lib/router'
EventBroker = require 'chaplin/lib/event_broker'

# The application bootstrapper
# ----------------------------

module.exports = class Application

  # Borrow the static extend method from Backbone
  @extend = Backbone.Model.extend

  # Mixin an EventBroker
  _(@prototype).extend EventBroker

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
