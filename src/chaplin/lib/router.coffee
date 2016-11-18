import _ from 'underscore'
import Backbone from 'backbone'

import EventBroker from './event_broker'
import History from './history'
import Route from './route'
import utils from './utils'
import mediator from '../mediator'

# The router which is a replacement for Backbone.Router.
# Like the standard router, it creates a Backbone.History
# instance and registers routes on it.
export default class Router # This class does not extend Backbone.Router.
  # Borrow the static extend method from Backbone.
  @extend = Backbone.Model.extend

  # Mixin an EventBroker.
  _.extend @prototype, EventBroker

  constructor: (@options = {}) ->
    # Enable pushState by default for HTTP(s).
    # Disable it for file:// schema.
    isWebFile = window.location.protocol isnt 'file:'
    _.defaults @options,
      pushState: isWebFile
      root: '/'
      trailing: no

    # Cached regex for stripping a leading subdir and hash/slash.
    @removeRoot = new RegExp '^' + utils.escapeRegExp(@options.root) + '(#)?'

    @subscribeEvent '!router:route', @oldEventError
    @subscribeEvent '!router:routeByName', @oldEventError
    @subscribeEvent '!router:changeURL', @oldURLEventError

    @subscribeEvent 'dispatcher:dispatch', @changeURL

    mediator.setHandler 'router:route', @route, this
    mediator.setHandler 'router:reverse', @reverse, this

    @createHistory()

  oldEventError: ->
    throw new Error '!router:route and !router:routeByName events were removed.
  Use `Chaplin.utils.redirectTo`'

  oldURLEventError: ->
    throw new Error '!router:changeURL event was removed.'

  # Create a Backbone.History instance.
  createHistory: ->
    Backbone.history = new History()

  startHistory: ->
    # Start the Backbone.History instance to start routing.
    # This should be called after all routes have been registered.
    Backbone.history.start @options

  # Stop the current Backbone.History instance from observing URL changes.
  stopHistory: ->
    Backbone.history.stop() if Backbone.History.started

  # Search through backbone history handlers.
  findHandler: (predicate) ->
    for handler in Backbone.history.handlers when predicate handler
      return handler

  # Connect an address with a controller action.
  # Creates a route on the Backbone.History instance.
  match: (pattern, target, options = {}) =>
    if arguments.length is 2 and target and typeof target is 'object'
      # Handles cases like `match 'url', controller: 'c', action: 'a'`.
      {controller, action} = options = target
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
      [controller, action] = target.split '#'

    # Let each match call provide its own trailing option to appropriate Route.
    # Pass trailing value from the Router by default.
    _.defaults options, trailing: @options.trailing

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
  route: (pathDesc, params, options) ->
    # Try to extract an URL from the pathDesc if it's a hash.
    if pathDesc and typeof pathDesc is 'object'
      path = pathDesc.url
      params = pathDesc.params if not params and pathDesc.params

    params = if Array.isArray params
      params.slice()
    else
      _.extend {}, params

    # Accept path to be given via URL wrapped in object,
    # or implicitly via route name, or explicitly via object.
    if path?
      # Remove leading subdir and hash or slash.
      path = path.replace @removeRoot, ''

      # Find a matching route.
      handler = @findHandler (handler) -> handler.route.test path

      # Options is the second argument in this case.
      options = params
      params = null
    else
      options = _.extend {}, options

      # Find a route using a passed via pathDesc string route name.
      handler = @findHandler (handler) ->
        if handler.route.matches pathDesc
          params = handler.route.normalizeParams params
          return true if params
        false

    if handler
      # Update the URL programmatically after routing.
      _.defaults options, changeURL: true

      pathParams = if path? then path else params
      handler.callback pathParams, options
      true
    else
      throw new Error 'Router#route: request was not routed'

  # Find the URL for given criteria using the registered routes and
  # provided parameters. The criteria may be just the name of a route
  # or an object containing the name, controller, and/or action.
  # Warning: this is usually **hot** code in terms of performance.
  # Returns the URL string or false.
  reverse: (criteria, params, query) ->
    root = @options.root

    if params? and typeof params isnt 'object'
      throw new TypeError 'Router#reverse: params must be an array or an ' +
        'object'

    # First filter the route handlers to those that are of the same name.
    handlers = Backbone.history.handlers
    for handler in handlers when handler.route.matches criteria
      # Attempt to reverse using the provided parameter hash.
      reversed = handler.route.reverse params, query

      # Return the url if we got a valid one; else we continue on.
      if reversed isnt false
        url = if root then root + reversed else reversed
        return url

    # We didn't get anything.
    throw new Error 'Router#reverse: invalid route criteria specified: ' +
      "#{JSON.stringify criteria}"

  # Change the current URL, add a history entry.
  changeURL: (controller, params, route, options) ->
    return unless route.path? and options?.changeURL

    url = route.path + if route.query then "?#{route.query}" else ''

    navigateOptions =
      # Do not trigger or replace per default.
      trigger: options.trigger is true
      replace: options.replace is true

    # Navigate to the passed URL and forward options to Backbone.
    Backbone.history.navigate url, navigateOptions

  # Disposal
  # --------

  disposed: false

  dispose: ->
    return if @disposed

    # Stop Backbone.History instance and remove it.
    @stopHistory()
    delete Backbone.history

    @unsubscribeAllEvents()

    mediator.removeHandlers this

    # Finished.
    @disposed = true

    # You’re frozen when your heart’s not open.
    Object.freeze this
