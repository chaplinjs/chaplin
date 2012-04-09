define [
  'mediator',
  'chaplin/controllers/application_controller',
  'chaplin/views/application_view',
  'chaplin/lib/router',
  'lib/view_helper' # Just load the file, no return value
], (mediator, ApplicationController, ApplicationView, Router) ->
  'use strict'

  # The application bootstrapper.
  class Application

    # The site title used in the document title
    title: ''

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
      router = new Router()

      # We have to make the router public because
      # the AppView needs to access it synchronously.
      mediator.setRouter router

      # Register all routes declared in routes.coffee
      routes? router.match

      # After registering the routes, start Backbone.history
      router.startHistory()
