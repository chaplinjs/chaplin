define [
  'mediator',
  'chaplin/application',
  'controllers/session_controller',
  'controllers/navigation_controller', 'controllers/sidebar_controller',
  'routes',
  'chaplin/lib/support',
], (mediator, Application, SessionController, NavigationController, SidebarController, routes, support) ->
  'use strict'

  # The application bootstrapper.
  # You should find a better name for your application.
  class ExampleApplication extends Application

    # Set your application name here so the document title is set to
    # “Controller title – Site title” (see ApplicationView#adjustTitle)
    title: 'Chaplin Example Application'

    initialize: ->
      #console.debug 'ExampleApplication#initialize'

      super # This creates the AppController and AppView

      # Instantiate common controllers
      # ------------------------------

      new SessionController()
      new NavigationController()
      new SidebarController()

      # Initialize the router
      # ---------------------

      # This creates the mediator.router property and
      # starts the Backbone history.
      @initRouter routes

      # Object sealing
      # --------------

      # Seal the mediator object (prevent extensions and
      # make all properties non-configurable)
      if support.propertyDescriptors and Object.seal
        Object.seal mediator

      # Freeze the application instance to prevent further changes
      Object.freeze? this
