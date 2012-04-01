define ['mediator', 'lib/route'], (mediator, Route) ->
  'use strict'

  class Router # This class does not inherit from Backbone’s router

    constructor: ->
      # Create a Backbone.History instance
      @createHistory()

    createHistory: ->
      Backbone.history or= new Backbone.History

    startHistory: ->
      # Start the Backbone.History instance to start routing
      # This should be called after all routes have been registered
      Backbone.history.start pushState: true

    stopHistory: ->
      Backbone.history.stop()

    # Connect an address with a controller action
    # Directly create a route on the Backbone.History instance
    match: (pattern, target, options = {}) =>

      # Create a route
      route = new Route pattern, target, options

      # Register the route at the Backbone.History instance
      Backbone.history.route route, route.handler

    # Route a given URL path manually, return whether a route matched
    # This looks quite like Backbone.History::loadUrl but it
    # accepts an absolute URL with a leading slash (e.g. /foo)
    # and passes the changeURL param to the callback function
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
