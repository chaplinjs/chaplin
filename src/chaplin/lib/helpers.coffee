'use strict'

mediator = require 'chaplin/mediator'

helpers =
  # Routing Helpers
  # ---------------

  # Returns the url for a named route and any params.
  reverse: (criteria, params, query) ->
    mediator.execute 'router:reverse', criteria, params, query

  # Redirects to URL, route name or controller and action pair.
  redirectTo: (pathDesc, params, options) ->
    mediator.execute 'router:route', pathDesc, params, options

module.exports = helpers
