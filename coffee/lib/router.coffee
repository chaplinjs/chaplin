define ['mediator', 'lib/route'], (mediator, Route) ->
  'use strict'

  # The router which is a replacement for Backbone.Router.
  # Like the standard router, it creates a Backbone.History
  # instance and registers routes on it.

  class Router # This class does not extend Backbone.Router

    constructor: ->
      @createHistory()

    # Create a Backbone.History instance
    createHistory: ->
      Backbone.history or= new Backbone.History()

    startHistory: ->
      # Start the Backbone.History instance to start routing
      # This should be called after all routes have been registered
      Backbone.history.start pushState: true

    # Stop the current Backbone.History instance from observing URL changes
    stopHistory: ->
      Backbone.history.stop()

    # Stop and delete the Backbone.History instance
    deleteHistory: ->
      Backbone.history.stop()
      delete Backbone.history

    # Connect an address with a controller action
    # Directly create a route on the Backbone.History instance
    match: (pattern, target, options = {}) =>

      # Create a route
      route = new Route pattern, target, options

      # Register the route at the Backbone.History instance
      Backbone.history.route route, route.handler

    # Route a given URL path manually, returns whether a route matched
    # This looks quite like Backbone.History::loadUrl but it
    # accepts an absolute URL with a leading slash (e.g. /foo)
    # and passes a changeURL param to the callback function.
    route: (path) =>
      #console.debug 'Router#route', path

      # Remove leading hash or slash
      path = path.replace /^(\/#|\/)/, ''

      for handler in Backbone.history.handlers
        if handler.route.test(path)
          handler.callback path, changeURL: true
          return true
      false

    # Change the current URL, add a history entry.
    # Do not trigger any routes (which is Backbone’s
    # default behavior, but added for clarity)
    changeURL: (url) ->
      Backbone.history.navigate url, trigger: false
