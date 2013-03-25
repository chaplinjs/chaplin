'use strict'

mediator = require 'chaplin/mediator'

helpers =
  # Routing Helpers
  # ---------------

  # Returns the url for a named route and any params.
  reverse: (routeName, params...) ->
    url = null
    # Don't worry, this callback happens synchronously.
    mediator.publish '!router:reverse', routeName, params, (result) ->
      if result isnt false
        url = result
      else
        throw new Error 'Chaplin.helpers.reverse: invalid route specified.'
    url

module.exports = helpers
