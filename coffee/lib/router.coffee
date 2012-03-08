define ['mediator', 'lib/route', 'routes'], (mediator, Route, registerRoutes) ->
  'use strict'

  class Router # This class does not inherit from Backbone’s router
    constructor: ->
      registerRoutes @match
      # Start the Backbone History to start routing
      Backbone.history.start pushState: true

    # Connect an address with a controller action
    # Directly create a Backbone.history route
    match: (pattern, target, options = {}) =>
      # Create a Backbone history instance (singleton)
      Backbone.history or= new Backbone.History

      # Create a route
      route = new Route pattern, target, options

      # Register the route at the Backbone History instance
      Backbone.history.route route, route.handler

    # Route a given URL path manually, return whether a route matched
    # This looks quite like Backbone.History::loadUrl but it
    # accepted an absolute URL with a leading slash (e.g. /foo)
    # and passes the changeURL param to the callback function
    route: (path) =>
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
