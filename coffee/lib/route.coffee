define ['mediator'], (mediator)->

  'use strict'

  class Route

    @reservedParams: 'path navigate'.split(' ')

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

      # Apply the main RegExp
      matches = @regExp.exec path
      #console.debug 'matches', matches
      return false unless matches

      # Apply the parameter constraints
      constraints = @options.constraints
      if constraints
        params = @buildParams path, matches
        for own type, constraint of @constraints
          unless constraint.test(params[type])
            return false

      #console.debug 'matched!'
      return true

    # The handler which is called by Backbone.History when the route matched
    handler: (path, options = {}) =>
      #console.debug 'Route#handler', @, path, options

      # Build params hash
      params = @buildParams path

      # Only change the URL if explicitly stated
      params.navigate = options.navigate is true

      # Publish a global routeMatch event passing the route and the params
      mediator.publish 'matchRoute', @, params

    # Create a proper Rails-like params hash, not an array like Backbone
    # `matches` argument is optional
    buildParams: (path, matches) ->
      #console.debug 'Route#buildParams', 'path', path, 'matches', matches

      params = {}
      matches or= @regExp.exec path

      # Fill the hash using the paramNames and the matches
      for match, index in matches.slice(1)
        paramName = @paramNames[index]
        params[paramName] = match

      # Add a param with the whole path match
      params.path = matches[0]
      #console.debug '\tparams', params

      params
