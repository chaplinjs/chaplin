'use strict'

mediator = require 'chaplin/mediator'

helpers =

  # Routing Helpers
  # --------------

  # Returns the url for a named route and any params
  reverse: (routeName, params...) ->
    url = false
    # Don't worry, this callback happens synchronously
    mediator.publish '!router:reverse', routeName, params, (result) ->
      url = "/#{result}" if result
    url

module.exports = helpers
