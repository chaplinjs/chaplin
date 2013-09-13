'use strict'

_ = require 'underscore'
Backbone = require 'backbone'
EventBroker = require 'chaplin/lib/event_broker'
Controller = require 'chaplin/controllers/controller'
utils = require 'chaplin/lib/utils'

module.exports = class Route
  # Borrow the static extend method from Backbone.
  @extend = Backbone.Model.extend

  # Mixin an EventBroker.
  _.extend @prototype, EventBroker

  # Taken from Backbone.Router.
  escapeRegExp = /[-[\]{}()+?.,\\^$|#\s]/g

  # Create a route for a URL pattern and a controller action
  # e.g. new Route '/users/:id', 'users', 'show', { some: 'options' }
  constructor: (@pattern, @controller, @action, options) ->
    # Disallow regexp routes.
    if _.isRegExp @pattern
      throw new Error 'Route: RegExps are not supported.
        Use strings with :names and `constraints` option of route'

    # Clone options.
    @options = if options then _.clone(options) else {}

    # Store the name on the route if given
    @name = @options.name if @options.name?

    # Don’t allow ambiguity with controller#action.
    if @name and @name.indexOf('#') isnt -1
      throw new Error 'Route: "#" cannot be used in name'

    # Set default route name.
    @name ?= @controller + '#' + @action

    # Initialize list of :params which the route will use.
    @paramNames = []

    # Check if the action is a reserved name
    if _.has Controller.prototype, @action
      throw new Error 'Route: You should not use existing controller ' +
        'properties as action names'

    @createRegExp()

    # You’re frozen when your heart’s not open.
    Object.freeze? this

  # Tests if route params are equal to criteria.
  matches: (criteria) ->
    if typeof criteria is 'string'
      criteria is @name
    else
      propertiesCount = 0
      for name in ['name', 'action', 'controller']
        propertiesCount++
        property = criteria[name]
        return false if property and property isnt this[name]
      invalidParamsCount = propertiesCount is 1 and name in ['action', 'controller']
      not invalidParamsCount

  # Generates route URL from params.
  reverse: (params, query) ->
    params = @normalizeParams params
    return false if params is false

    url = @pattern

    # From a params hash; we need to be able to return
    # the actual URL this route represents.
    # Iterate and replace params in pattern.
    for name in @paramNames
      value = params[name]
      url = url.replace ///[:*]#{name}///g, value

    return url unless query

    # Stringify query params if needed.
    if typeof query is 'object'
      url += '?' + utils.QueryParams.stringify query
    else
      url += (if query[0] is '?' then '' else '?') + query

  # Validates incoming params and returns them in a unified form - hash
  normalizeParams: (params) ->
    if _.isArray params
      # Ensure we have enough parameters.
      return false if params.length < @paramNames.length

      # Convert params from array into object.
      paramsHash = {}
      for paramName, paramIndex in @paramNames
        paramsHash[paramName] = params[paramIndex]

      return false unless @testConstraints paramsHash

      params = paramsHash
    else
      # null or undefined params are equivalent to an empty hash
      params ?= {}

      return false unless @testParams params

    params

  # Test if passed params hash matches current constraints.
  testConstraints: (params) ->
    # Apply the parameter constraints.
    constraints = @options.constraints
    if constraints
      for own name, constraint of constraints
        return false unless constraint.test params[name]

    true

  # Test if passed params hash matches current route.
  testParams: (params) ->
    # Ensure that params contains all the parameters needed.
    for paramName in @paramNames
      return false if params[paramName] is undefined

    @testConstraints params

  # Creates the actual regular expression that Backbone.History#loadUrl
  # uses to determine if the current url is a match.
  createRegExp: ->
    pattern = @pattern
      # Escape magic characters.
      .replace(escapeRegExp, '\\$&')
      # Replace named parameters, collecting their names.
      .replace(/(?::|\*)(\w+)/g, @addParamName)

    # Create the actual regular expression, match until the end of the URL or
    # the begin of query string.
    @regExp = ///^#{pattern}(?=\?|$)///

  addParamName: (match, paramName) =>
    # Save parameter name.
    @paramNames.push paramName
    # Replace with a character class.
    if match.charAt(0) is ':'
      # Regexp for :foo.
      '([^\/\?]+)'
    else
      # Regexp for *foo.
      '(.*?)'

  # Test if the route matches to a path (called by Backbone.History#loadUrl).
  test: (path) ->
    # Test the main RegExp.
    matched = @regExp.test path
    return false unless matched

    # Apply the parameter constraints.
    constraints = @options.constraints
    if constraints
      return @testConstraints @extractParams path

    true

  # The handler called by Backbone.History when the route matches.
  # It is also called by Router#route which might pass options.
  handler: (pathParams, options) =>
    options = if options then _.clone options else {}

    # pathDesc may be either an object with params for reversing or a simple URL.
    if typeof pathParams is 'object'
      query = utils.QueryParams.stringify options.query
      params = pathParams
      path = @reverse params
    else
      [path, query] = pathParams.split '?'
      if not query?
        query = ''
      else
        options.query = utils.QueryParams.parse query
      params = @extractParams path

    actionParams = _.extend {}, params, @options.params

    # Construct a route object to forward to the match event.
    route = {path, @action, @controller, @name, query}

    # Publish a global event passing the route and the params.
    # Original options hash forwarded to allow further forwarding to backbone.
    @publishEvent 'router:match', route, actionParams, options

  # Extract named parameters from the URL path.
  extractParams: (path) ->
    params = {}

    # Apply the regular expression.
    matches = @regExp.exec path

    # Fill the hash using the paramNames and the matches.
    for match, index in matches.slice(1)
      paramName = if @paramNames.length then @paramNames[index] else index
      params[paramName] = match

    params
