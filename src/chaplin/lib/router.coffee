define [
  'underscore'
  'backbone'
  'chaplin/mediator'
  'chaplin/lib/event_broker'
  'chaplin/lib/route'
], (_, Backbone, mediator, EventBroker, Route) ->
  'use strict'

  # The router which is a replacement for Backbone.Router.
  # Like the standard router, it creates a Backbone.History
  # instance and registers routes on it.

  class Router # This class does not extend Backbone.Router

    # Borrow the static extend method from Backbone
    @extend = Backbone.Model.extend

    # Mixin an EventBroker
    _(@prototype).extend EventBroker

    constructor: (@options = {}) ->
      _(@options).defaults
        pushState: true

      @subscribeEvent '!router:route', @routeHandler
      @subscribeEvent '!router:changeURL', @changeURLHandler

      @createHistory()

    # Create a Backbone.History instance
    createHistory: ->
      Backbone.history or= new Backbone.History()

    startHistory: ->
      # Start the Backbone.History instance to start routing
      # This should be called after all routes have been registered
      Backbone.history.start @options

    # Stop the current Backbone.History instance from observing URL changes
    stopHistory: ->
      Backbone.history.stop() if Backbone.History.started

    # Connect an address with a controller action
    # Directly create a route on the Backbone.History instance
    match: (pattern, target, options = {}) =>
      # Create the route
      route = new Route pattern, target, options
      # Register the route at the Backbone.History instance.
      # Don’t use Backbone.history.route here because it calls
      # handlers.unshift, inserting the handler at the top of the list.
      # Since we want routes to match in the order they were specified,
      # we’re appending the route at the end.
      Backbone.history.handlers.push {route, callback: route.handler}
      route

    # Route a given URL path manually, returns whether a route matched
    # This looks quite like Backbone.History::loadUrl but it
    # accepts an absolute URL with a leading slash (e.g. /foo)
    # and passes a changeURL param to the callback function.
    route: (path, options = {}) =>
      # Default options to changeURL: true to mimic existing behavior while
      # allowing additional options to be forwarded on
      _(options).defaults
        changeURL: true

      # Remove leading hash or slash
      path = path.replace /^(\/#|\/)/, ''
      for handler in Backbone.history.handlers
        if handler.route.test(path)
          handler.callback path, options
          return true
      false

    # Handler for the global !router:route event
    routeHandler: (path, options, callback) ->
      # Assume only path and callback were passed if we only got 2 arguments;
      # so as to mimic existing chaplin behavior
      [callback, options] = [options, {}] if arguments.length is 2

      # Continue on to handle the route; pass in options hash
      routed = @route path, options
      callback? routed

    # Change the current URL, add a history entry.
    changeURL: (url, options = {}) ->
      # Default options to trigger: false (which is Backbone’s
      # default behavior, but added for clarity)
      _(options).defaults
        trigger: false

      # Navigate to the passed URL and forward options to backbone
      Backbone.history.navigate url, options

    # Handler for the global !router:changeURL event
    # Accepts both the url and an options hash that is forwarded to backbone
    changeURLHandler: (url, options = {}) ->
      @changeURL url, options

    # Disposal
    # --------

    disposed: false

    dispose: ->
      return if @disposed

      # Stop Backbone.History instance and remove it
      @stopHistory()
      delete Backbone.history

      @unsubscribeAllEvents()

      # Finished
      @disposed = true

      # You’re frozen when your heart’s not open
      Object.freeze? this
