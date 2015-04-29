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
  escapeRegExp = /[\-{}\[\]+?.,\\\^$|#\s]/g
  optionalRegExp = /\((.*?)\)/g
  paramRegExp = /(?::|\*)(\w+)/g

  # Add or remove trailing slash from path according to trailing option.
  processTrailingSlash = (path, trailing) ->
    switch trailing
      when yes
        path += '/' unless path[-1..] is '/'
      when no
        path = path[...-1] if path[-1..] is '/'
    path

  # Create a route for a URL pattern and a controller action
  # e.g. new Route '/users/:id', 'users', 'show', { some: 'options' }
  constructor: (@pattern, @controller, @action, options) ->
    # Disallow regexp routes.
    if typeof @pattern isnt 'string'
      throw new Error 'Route: RegExps are not supported.
        Use strings with :names and `constraints` option of route'

    # Clone options.
    @options = if options then _.extend({}, options) else {}

    @options.paramsInQS = true if @options.paramsInQS isnt false

    # Store the name on the route if given
    @name = @options.name if @options.name?

    # Don’t allow ambiguity with controller#action.
    if @name and @name.indexOf('#') isnt -1
      throw new Error 'Route: "#" cannot be used in name'

    # Set default route name.
    @name ?= @controller + '#' + @action

    # Initialize list of :params which the route will use.
    @allParams = []
    @requiredParams = []
    @optionalParams = []

    # Check if the action is a reserved name
    if @action of Controller.prototype
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
    remainingParams = _.extend {}, params
    return false if params is false

    url = @pattern

    # From a params hash; we need to be able to return
    # the actual URL this route represents.
    # Iterate and replace params in pattern.
    for name in @requiredParams
      value = params[name]
      url = url.replace ///[:*]#{name}///g, value
      delete remainingParams[name]

    # Replace optional params.
    for name in @optionalParams
      if value = params[name]
        url = url.replace ///[:*]#{name}///g, value
        delete remainingParams[name]

    # Kill unfulfilled optional portions.
    raw = url.replace optionalRegExp, (match, portion) ->
      if portion.match /[:*]/g
        ""
      else
        portion

    # Add or remove trailing slash according to the Route options.
    url = processTrailingSlash raw, @options.trailing

    query = utils.queryParams.parse query if typeof query isnt 'object'
    _.extend query, remainingParams unless @options.paramsInQS is false
    url += '?' + utils.queryParams.stringify query unless _.isEmpty query
    url

  # Validates incoming params and returns them in a unified form - hash
  normalizeParams: (params) ->
    if utils.isArray params
      # Ensure we have enough parameters.
      return false if params.length < @requiredParams.length

      # Convert params from array into object.
      paramsHash = {}
      routeParams = @requiredParams.concat @optionalParams
      for paramIndex in [0..params.length-1] by 1
        paramName = routeParams[paramIndex]
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
    for paramName in @requiredParams
      return false if params[paramName] is undefined

    @testConstraints params

  # Creates the actual regular expression that Backbone.History#loadUrl
  # uses to determine if the current url is a match.
  createRegExp: ->
    pattern = @pattern

    # Escape magic characters.
    pattern = pattern.replace(escapeRegExp, '\\$&')

    # Keep accurate back-reference indices in allParams.
    # Eg. Matching the regex returns arrays like [a, undefined, c]
    #  and each item needs to be matched to the correct
    #  named parameter via its position in the array.
    @replaceParams pattern, (match, param) =>
      @allParams.push param

    # Process optional route portions.
    pattern = pattern.replace optionalRegExp, @parseOptionalPortion

    # Process remaining required params.
    pattern = @replaceParams pattern, (match, param) =>
      @requiredParams.push param
      @paramCapturePattern match

    # Create the actual regular expression, match until the end of the URL,
    # trailing slash or the begin of query string.
    @regExp = ///^#{pattern}(?=\/*(?=\?|$))///

  parseOptionalPortion: (match, optionalPortion) =>
    # Extract and replace params.
    portion = @replaceParams optionalPortion, (match, param) =>
      @optionalParams.push param
      # Replace the match (eg. :foo) with capturing groups.
      @paramCapturePattern match

    # Replace the optional portion with a non-capturing and optional group.
    "(?:#{portion})?"

  replaceParams: (s, callback) =>
    # Parse :foo and *bar, replacing via callback.
    s.replace paramRegExp, callback

  paramCapturePattern: (param) ->
    if param.charAt(0) is ':'
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
    options = if options then _.extend {}, options else {}

    # pathDesc may be either an object with params for reversing or a simple URL.
    if typeof pathParams is 'object'
      query = utils.queryParams.stringify options.query
      params = pathParams
      path = @reverse params
    else
      [path, query] = pathParams.split '?'
      if not query?
        query = ''
      else
        options.query = utils.queryParams.parse query
      params = @extractParams path
      path = processTrailingSlash path, @options.trailing

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

    # Fill the hash using param names and the matches.
    for match, index in matches.slice(1)
      paramName = if @allParams.length then @allParams[index] else index
      params[paramName] = match

    params
