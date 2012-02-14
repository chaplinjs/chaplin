define ['mediator', 'lib/route'], (mediator, Route) ->

  'use strict'

  class Router

    constructor: ->
      @registerRoutes()
      @startHistory()

    registerRoutes: ->

      # ---- THE INTREDASTING PART STARTS: ---- #

      @match '', 'likes#index'
      @match 'likes/:id', 'likes#show'

      @match 'posts', 'posts#index'

      # ---- THE INTREDASTING PART ENDS. ---- #

    # Start the Backbone History to start routing

    startHistory: ->
      Backbone.history.start pushState: true

    # Connect an address with a controller action
    # Don’t use Backbone’s Router#route, directly create a Backbone.history route instead

    match: (expression, target, options = {}) ->
      #console.debug 'Router#match', expression, controller

      # Create a Backbone history instance (singleton)
      Backbone.history or= new Backbone.History

      # Create a route
      route = new Route expression, target, options
      #console.debug 'created route', route

      # Register the route at the Backbone History instance
      Backbone.history.route route, route.handler

    # Route a given URL path manually, return whether a route matched

    follow: (path, params = {}) =>
      #console.debug 'Router#follow', path, params

      path = path.replace /^(\/#|\/)/, ''
      for handler in Backbone.history.handlers
        if handler.route.test(path)
          handler.callback path, params
          return true
      return false

    # Change the current URL, add a history entry.
    # Do not trigger any routes (which is Backbone’s
    # default behavior, but added for clarity)

    navigate: (url) ->
      #console.debug 'Router#navigate', url
      Backbone.history.navigate url, trigger: false
