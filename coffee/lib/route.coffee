define ['mediator'], (mediator)->

  'use strict'

  class Route

    @reservedParams: 'path navigate'.split(' ')

    constructor: (expression, target, @options = {}) ->
      #console.debug 'Router#constructor'

      # Separate target into controller and controller action
      [@controller, @action] = target.split('#')

      # Replace :parameters, collecting their names
      @paramNames = []
      expression = expression.replace /:(\w+)/g, @addParamName

      # Create the actual regular expression
      @regExp = new RegExp '^' + expression + '(?=\\?|$)' # End or query string

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

      # Startup the module controller
      #console.debug '\tstartup', 'controller:', @controller, 'action:', @action, 'params:', params, 'navigate:', params.navigate
      mediator.publish '!startupController', @controller, @action, params

    # Create a proper Rails-like params hash, not an array like Backbone
    # `matches` argument is optional
    buildParams: (path, matches) ->
      #console.debug 'Route#buildParams', 'path', path, 'matches', matches

      matches or= @regExp.exec path

      # Build the hash using the paramNames and the matches
      params = {}
      for match, index in matches.slice(1)
        paramName = @paramNames[index]
        params[paramName] = match

      # Add a param with the whole path match
      params.path = matches[0]
      #console.debug '\tparams', params

      params
