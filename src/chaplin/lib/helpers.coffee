'use strict'

mediator = require 'chaplin/mediator'

helpers =
  # Routing Helpers
  # ---------------

  # Returns the url for a named route and any params.
  reverse: (routeName, params) ->
    url = null
    # Don't worry, this callback happens synchronously.
    mediator.publish '!router:reverse', routeName, params, (result) ->
      url = result
    url

module.exports = helpers
