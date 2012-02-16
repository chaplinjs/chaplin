define ['mediator'], (mediator)->

  'use strict'

  class Route

    @reservedParams: 'path changeURL'.split(' ')

    constructor: (pattern, target, @options = {}) ->
      #console.debug 'Router#constructor'

      # Save the raw pattern
      @pattern = pattern

      # Separate target into controller and controller action
      [@controller, @action] = target.split('#')

      # Replace :parameters, collecting their names
      @paramNames = []
      pattern = pattern.replace /:(\w+)/g, @addParamName

      # Create the actual regular expression
      @regExp = new RegExp '^' + pattern + '(?=\\?|$)' # End or begin of query string

    addParamName: (match, paramName) =>
      # Test if parameter name is reserved
      if _(Route.reservedParams).include(paramName)
        throw new Error "Route#new: parameter name #{paramName} is reserved"
      # Save parameter name
      @paramNames.push paramName
      # Replace with a character class
      '([\\w-]+)'

    # Test if the route matches to a path (called by Backbone.History#loadUrl)

    test: (path) ->
      #console.debug 'Route#test', @, "path »#{path}«", typeof path

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
    # It is also called by Router#follow which might pass options

    handler: (path, options) =>
      #console.debug 'Route#handler', @, path, options

      # Build params hash
      params = @buildParams path, options

      # Publish a global routeMatch event passing the route and the params
      mediator.publish 'matchRoute', @, params

    # Create a proper Rails-like params hash, not an array like Backbone
    # `matches` and `additionalParams` arguments are optional

    buildParams: (path, options) ->
      #console.debug 'Route#buildParams', path, options

      params = @extractParams path

      # Add additional params from options
      # (they might overwrite params extracted from URL)
      _(params).extend @options.params

      # Add a param whether to change the URL
      # Defaults to false unless explicitly set in options
      params.changeURL = Boolean(options and options.changeURL)

      # Add a param with the whole path match
      params.path = path

      params

    # Extract parameters from the URL

    extractParams: (path) ->
      params = {}

      # Apply the regular expression
      matches = @regExp.exec path

      # Fill the hash using the paramNames and the matches
      for match, index in matches.slice(1)
        paramName = @paramNames[index]
        params[paramName] = match

      params