define [
  'underscore'
  'backbone'
  'chaplin/lib/event_broker'
  'chaplin/controllers/controller'
], (_, Backbone, EventBroker, Controller) ->
  'use strict'

  class Route

    # Borrow the static extend method from Backbone
    @extend = Backbone.Model.extend

    # Mixin an EventBroker
    _(@prototype).extend EventBroker

    reservedParams = ['path', 'changeURL']
    # Taken from Backbone.Router
    escapeRegExp = /[-[\]{}()+?.,\\^$|#\s]/g

    queryStringFieldSeparator = '&'
    queryStringValueSeparator = '='

    # Create a route for a URL pattern and a controller action
    # e.g. new Route '/users/:id', 'users#show'
    constructor: (pattern, target, @options = {}) ->
      # Save the raw pattern
      @pattern = pattern

      # Store the name on the route if given
      @name = @options.name if @options.name?

      # Separate target into controller and controller action
      [@controller, @action] = target.split('#')

      # Check if the action is a reserved name
      if _(Controller.prototype).has @action
        throw new Error 'Route: You should not use existing controller properties as action names'

      @createRegExp()

    reverse: (params) ->
      url = @pattern
      # TODO: add support for regular expressions in reverser.
      return false if _.isRegExp url

      # From a params hash; we need to be able to return
      # the actual URL this route represents
      # Iterate and attempt to replace params in pattern
      for name, value of params
        url = url.replace ///:#{name}///g, value
        url = url.replace ///\*#{name}///g, value

      # If the url tests out good; return the url; else, false
      if @test url then url else false

    createRegExp: ->
      if _.isRegExp(@pattern)
        @regExp = @pattern
        @paramNames = @options.names if _.isArray @options.names
        return

      pattern = @pattern
        # Escape magic characters
        .replace(escapeRegExp, '\\$&')
        # Replace named parameters, collecting their names
        .replace(/(?::|\*)(\w+)/g, @addParamName)

      # Create the actual regular expression
      # Match until the end of the URL or the begin of query string
      @regExp = ///^#{pattern}(?=\?|$)///

    addParamName: (match, paramName) =>
      @paramNames ?= []
      # Test if parameter name is reserved
      if _(reservedParams).include(paramName)
        throw new Error "Route#addParamName: parameter name #{paramName} is reserved"
      # Save parameter name
      @paramNames.push paramName
      # Replace with a character class
      if match.charAt(0) is ':'
        # Regexp for :foo
        '([^\/\?]+)'
      else
        # Regexp for *foo
        '(.*?)'

    # Test if the route matches to a path (called by Backbone.History#loadUrl)
    test: (path) ->
      # Test the main RegExp
      matched = @regExp.test path
      return false unless matched

      # Apply the parameter constraints
      constraints = @options.constraints
      if constraints
        params = @extractParams path
        for own name, constraint of constraints
          unless constraint.test(params[name])
            return false

      return true

    # The handler which is called by Backbone.History when the route matched.
    # It is also called by Router#route which might pass options
    handler: (path, options = {}) =>
      # Build params hash
      params = @buildParams path

      # Add a `path` routing option with the whole path match
      options.path = path

      # Publish a global matchRoute event passing the route and the params
      # Original options hash forwarded to allow further forwarding to backbone
      @publishEvent 'matchRoute', this, params, options

    # Create a proper Rails-like params hash, not an array like Backbone
    buildParams: (path) ->
      _.extend {},
        # Add params from query string
        @extractQueryParams(path),
        # Add named params from pattern matches
        @extractParams(path),
        # Add additional params from options
        # (they might overwrite params extracted from URL)
        @options.params

    # Extract named parameters from the URL path
    extractParams: (path) ->
      params = {}

      # Apply the regular expression
      matches = @regExp.exec path

      # Fill the hash using the paramNames and the matches
      for match, index in matches.slice(1)
        paramName = if @paramNames then @paramNames[index] else index
        params[paramName] = match

      params

    # Extract parameters from the query string
    extractQueryParams: (path) ->
      params = {}

      regExp = /\?(.+?)(?=#|$)/
      matches = regExp.exec path
      return params unless matches

      queryString = matches[1]
      pairs = queryString.split queryStringFieldSeparator
      for pair in pairs
        continue unless pair.length
        [field, value] = pair.split queryStringValueSeparator
        continue unless field.length
        field = decodeURIComponent field
        value = decodeURIComponent value
        current = params[field]
        if current
          # Handle multiple params with same name:
          # Aggregate them in an array
          if current.push
            # Add the existing array
            current.push value
          else
            # Create a new array
            params[field] = [current, value]
        else
          params[field] = value

      params
