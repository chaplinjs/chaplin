'use strict'

mediator = require 'chaplin/mediator'

helpers =
  # Routing Helpers
  # ---------------

  # Returns the url for a named route and any params.
  reverse: (routeName, params) ->
    mediator.getHandler('router:reverse')(routeName, params)

  # Redirects to URL or route name.
  redirectTo: (pathDesc, options) ->
    mediator.getHandler('router:route')(pathDesc, options)

module.exports = helpers
