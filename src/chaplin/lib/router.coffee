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
      @subscribeEvent '!router:reverse', @reverseHandler
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
    # Creates a route on the Backbone.History instance
    match: (pattern, target, options = {}) =>
      if arguments.length is 2 and typeof target is 'object'
        # Handles cases like `match 'url', controller: 'c', action: 'a'`.
        options = target
        {controller, action} = options
        unless controller and action
          throw new Error 'Router#match must receive either target or options.controller & options.action'
      else
        # Handles `match 'url', 'c#a'`.
        {controller, action} = options
        if controller or action
          throw new Error 'Router#match cannot use both target and options.controller / action'
        # Separate target into controller and controller action.
        [controller, action] = target.split('#')

      # Create the route
      route = new Route pattern, controller, action, options
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
      _(options).defaults
        changeURL: true

      # Remove leading hash or slash
      path = path.replace /^(\/#|\/)/, ''
      for handler in Backbone.history.handlers
        if handler.route.test(path)
          handler.callback path, options
          return true
      false

    reverseHandler: (name, params, callback) ->
      callback @reverse name, params

    # Find the URL for a given name using the registered routes and
    # provided parameters.
    reverse: (name, params) ->
      # First filter the route handlers to those that are of the same
      # name
      for handler in Backbone.history.handlers when handler.route.name is name
        # Attempt to reverse using the provided parameter hash
        url = handler.route.reverse params

        # Return the url if we got a valid one; else we continue on
        return url if url isnt false

      # We didn't get anything
      false

    # Handler for the global !router:route event
    routeHandler: (path, options, callback) ->
      # Support old signature: Assume only path and callback were passed
      # if we only got two arguments
      if arguments.length is 2 and typeof options is 'function'
        callback = options
        options = {}

      routed = @route path, options
      callback? routed

    # Change the current URL, add a history entry.
    changeURL: (url, options = {}) ->
      navigateOptions =
        # Do not trigger or replace per default
        trigger: options.trigger is true
        replace: options.replace is true

      # Navigate to the passed URL and forward options to Backbone
      Backbone.history.navigate url, navigateOptions

    # Handler for the global !router:changeURL event
    # Accepts both the url and an options hash that is forwarded to Backbone
    changeURLHandler: (url, options) ->
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
