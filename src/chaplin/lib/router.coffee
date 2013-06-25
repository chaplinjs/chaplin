'use strict'

_ = require 'underscore'
Backbone = require 'backbone'
EventBroker = require 'chaplin/lib/event_broker'
Route = require 'chaplin/lib/route'
utils = require 'chaplin/lib/utils'

# The router which is a replacement for Backbone.Router.
# Like the standard router, it creates a Backbone.History
# instance and registers routes on it.
module.exports = class Router # This class does not extend Backbone.Router.
  # Borrow the static extend method from Backbone.
  @extend = Backbone.Model.extend

  # Mixin an EventBroker.
  _.extend @prototype, EventBroker

  constructor: (@options = {}) ->
    _.defaults @options,
      pushState: true
      root: '/'

    # Cached regex for stripping a leading subdir and hash/slash.
    @removeRoot = new RegExp('^' + utils.escapeRegExp(@options.root) + '(#)?')

    @subscribeEvent '!router:route', @routeHandler
    @subscribeEvent '!router:routeByName', @routeByNameHandler
    @subscribeEvent '!router:reverse', @reverseHandler
    @subscribeEvent '!router:changeURL', @changeURLHandler

    @createHistory()

  # Create a Backbone.History instance.
  createHistory: ->
    Backbone.history or= new Backbone.History()

  startHistory: ->
    # Start the Backbone.History instance to start routing.
    # This should be called after all routes have been registered.
    Backbone.history.start @options

  # Stop the current Backbone.History instance from observing URL changes.
  stopHistory: ->
    Backbone.history.stop() if Backbone.History.started

  # Connect an address with a controller action.
  # Creates a route on the Backbone.History instance.
  match: (pattern, target, options = {}) =>
    if arguments.length is 2 and typeof target is 'object'
      # Handles cases like `match 'url', controller: 'c', action: 'a'`.
      options = target
      {controller, action} = options
      unless controller and action
        throw new Error 'Router#match must receive either target or ' +
          'options.controller & options.action'
    else
      # Handles `match 'url', 'c#a'`.
      {controller, action} = options
      if controller or action
        throw new Error 'Router#match cannot use both target and ' +
          'options.controller / options.action'
      # Separate target into controller and controller action.
      [controller, action] = target.split('#')

    # Create the route.
    route = new Route pattern, controller, action, options
    # Register the route at the Backbone.History instance.
    # Don’t use Backbone.history.route here because it calls
    # handlers.unshift, inserting the handler at the top of the list.
    # Since we want routes to match in the order they were specified,
    # we’re appending the route at the end.
    Backbone.history.handlers.push {route, callback: route.handler}
    route

  # Route a given URL path manually. Returns whether a route matched.
  # This looks quite like Backbone.History::loadUrl but it
  # accepts an absolute URL with a leading slash (e.g. /foo)
  # and passes the routing options to the callback function.
  route: (path, options) =>
    options = if options then _.clone(options) else {}

    # Update the URL programmatically after routing.
    _.defaults options, changeURL: true

    # Remove leading subdir and hash or slash.
    path = path.replace @removeRoot, ''

    # Find a matching route.
    for handler in Backbone.history.handlers
      if handler.route.test(path)
        handler.callback path, options
        return true

    throw new Error 'Router#route: request was not routed'

  # Find the URL for given criteria using the registered routes and
  # provided parameters. The criteria may be just the name of a route
  # or an object containing the name, controller, and/or action.
  # Warning: this is usually **hot** code in terms of performance.
  # Returns the URL string or false.
  reverse: (criteria, params) ->
    root = @options.root

    if params? and typeof params isnt 'object'
      throw new TypeError 'Router#reverse: params must be an array or an ' +
        'object'

    # First filter the route handlers to those that are of the same name.
    handlers = Backbone.history.handlers
    for handler in handlers when handler.route.matches criteria
      # Attempt to reverse using the provided parameter hash.
      reversed = handler.route.reverse params

      # Return the url if we got a valid one; else we continue on.
      if reversed isnt false
        url = if root then root + reversed else reversed
        return url

    # We didn't get anything.
    throw new Error 'Router#reverse: invalid route specified'

  # Handler for the global !router:route event.
  routeHandler: (path, options) ->
    # Support old signature: Assume only path and callback were passed
    # if we only got two arguments.
    options = {} if typeof options is 'function'
    @route path, options

  # Find the URL for a given route name and parameters,
  # then route the URL. Returns whether a route matched.
  # Handler for the global !router:routeByName event.
  routeByNameHandler: (name, params, options, callback) ->
    # Support old signature: Assume options wasn't passed
    # if we only got three arguments.
    options = {} if arguments.length is 3 and typeof options is 'function'
    path = @reverse name, params
    @route path, options

  # Handler for the global !router:reverse event.
  reverseHandler: (name, params, callback) ->
    callback @reverse name, params

  # Change the current URL, add a history entry.
  changeURL: (url, options = {}) ->
    navigateOptions =
      # Do not trigger or replace per default.
      trigger: options.trigger is true
      replace: options.replace is true

    # Navigate to the passed URL and forward options to Backbone.
    Backbone.history.navigate url, navigateOptions

  # Handler for the global !router:changeURL event.
  # Accepts both the url and an options hash that is forwarded to Backbone.
  changeURLHandler: (url, options) ->
    @changeURL url, options

  # Disposal
  # --------

  disposed: false

  dispose: ->
    return if @disposed

    # Stop Backbone.History instance and remove it.
    @stopHistory()
    delete Backbone.history

    @unsubscribeAllEvents()

    # Finished.
    @disposed = true

    # You’re frozen when your heart’s not open.
    Object.freeze? this
