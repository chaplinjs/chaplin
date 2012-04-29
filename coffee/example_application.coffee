define [
  'mediator',
  'chaplin/core',
  'views/application_layout',
  'controllers/session_controller',
  'controllers/navigation_controller',
  'controllers/sidebar_controller',
  'routes'
], (mediator, ChaplinCore, ApplicationLayout, SessionController, NavigationController, SidebarController, routes) ->
  'use strict'

  # The application bootstrapper.
  # You should find a better name for your application.
  class ExampleApplication extends ChaplinCore

    # Set your application name here so the document title is set to
    # “Controller title – Site title” (see ApplicationView#adjustTitle)
    title: 'Chaplin Example Application'

    initialize: ->
      ###console.debug 'ExampleApplication#initialize'###

      # This creates the ApplicationController and ApplicationView
      super

      # Instantiate layout
      # ------------------

      @layout = new ApplicationLayout title: @title


      # Instantiate common controllers
      # ------------------------------

      # These controllers are active during the whole application runtime.
      new SessionController()
      new NavigationController()
      new SidebarController()

      # Initialize the router
      # ---------------------

      # This creates the mediator.router property and
      # starts the Backbone history.
      @initRouter routes

      # Finish
      # ------

      # Freeze the application instance to prevent further changes
      Object.freeze? this
