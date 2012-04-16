mediator = require 'mediator'
ApplicationController = require 'chaplin/controllers/application_controller'
ApplicationView = require 'chaplin/views/application_view'
Router = require 'chaplin/lib/router'
require 'lib/view_helper'

# The application bootstrapper
# ----------------------------

module.exports = class Application

  # The site title used in the document title
  title: ''

  # The application instantiates these three core modules
  applicationController: null
  applicationView: null
  router: null

  initialize: ->
    #console.debug 'Application#initialize'

    # Instantiate the AppController and AppView
    # -----------------------------------------

    # Save the references for testing introspection only.
    # Module should communicate with each other via Pub/Sub.
    @applicationController = new ApplicationController()
    @applicationView = new ApplicationView title: @title

  # Instantiate the router
  # ----------------------

  # Pass the function typically returned by routes.coffee
  initRouter: (routes) ->
    # Save the reference for testing introspection only.
    # Module should communicate with each other via Pub/Sub.
    @router = new Router()

    # Register all routes declared in routes.coffee
    routes? @router.match

    # After registering the routes, start Backbone.history
    @router.startHistory()

  # Disposal
  # --------

  disposed: false

  dispose: ->
    return if @disposed

    properties = ['applicationController', 'applicationView', 'router']
    for prop in properties
      this[prop].dispose()
      delete this[prop]

    @disposed = true

    # Your're frozen when your heart’s not open
    Object.freeze? this
