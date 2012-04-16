define [
  'underscore',
  'mediator',
  'chaplin/lib/utils'
], (_, mediator, chaplinUtils) ->

  # Application-specific utilities
  # ------------------------------

  # Delegate to Chaplin’s utils module
  utils = chaplinUtils.beget chaplinUtils

  _(utils).extend

    # Facebook image helper
    # ---------------------

    facebookImageURL: (fbId, type = 'square') ->
      # Create query string
      params = type: type

      # Add the Facebook access token if present
      if mediator.user
        accessToken = mediator.user.get('accessToken')
        params.access_token = accessToken if accessToken

      "https://graph.facebook.com/#{fbId}/picture?#{$.param(params)}"

  utils
