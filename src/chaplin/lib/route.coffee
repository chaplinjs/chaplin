'use strict'

_ = require 'underscore'
Backbone = require 'backbone'
EventBroker = require 'chaplin/lib/event_broker'
Controller = require 'chaplin/controllers/controller'

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
      for name in ['name', 'action', 'controller']
        property = criteria[name]
        return false if property and property isnt this[name]
      true

  # Generates route URL from params.
  reverse: (params) ->
    url = @pattern
    if _.isArray params
      # Ensure we have enough parameters.
      return false if params.length < @paramNames.length

      index = 0
      url = url.replace /[:*][^\/\?]+/g, (match) ->
        result = params[index]
        index += 1
        result
    else
      # From a params hash; we need to be able to return
      # the actual URL this route represents
      # Iterate and attempt to replace params in pattern
      for name in @paramNames
        value = params[name]
        return false if value is undefined
        url = url.replace ///[:*]#{name}///g, value

    # If the url tests out good; return the url; else, false.
    if @test url then url else false

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
      if _.isFunction constraints
        return false unless constraints()
      else
        params = @extractParams path
        for own name, constraint of constraints
          return false unless constraint.test(params[name])

    return true

  # The handler called by Backbone.History when the route matches.
  # It is also called by Router#route which might pass options.
  handler: (path, options) =>
    options = if options then _.clone(options) else {}

    # If no query string was passed, use the current.
    query = options.query ? @getCurrentQuery()

    # Build params hash.
    params = @buildParams path, query

    # Construct a route object to forward to the match event.
    route = {path, @action, @controller, @name, query}

    # Remove the query string from routing options.
    delete options.query

    # Publish a global event passing the route and the params.
    # Original options hash forwarded to allow further forwarding to backbone.
    @publishEvent 'router:match', route, params, options

  # Returns the query string for the current document.
  getCurrentQuery: ->
    location.search.substring 1

  # Create a proper Rails-like params hash, not an array like Backbone.
  buildParams: (path, query) ->
    _.extend {},
      # Add params from query string.
      @extractQueryParams(query),
      # Add named params from pattern matches.
      @extractParams(path),
      # Add additional params from options as they might
      # overwrite params extracted from URL.
      @options.params

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

  # Extract parameters from the query string.
  extractQueryParams: (query) ->
    params = {}
    return params unless query
    pairs = query.split '&'
    for pair in pairs
      continue unless pair.length
      [field, value] = pair.split '='
      continue unless field.length
      field = decodeURIComponent field
      value = decodeURIComponent value
      current = params[field]
      if current
        # Handle multiple params with same name:
        # Aggregate them in an array.
        if current.push
          # Add the existing array.
          current.push value
        else
          # Create a new array.
          params[field] = [current, value]
      else
        params[field] = value

    params
