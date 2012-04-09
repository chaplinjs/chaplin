define [
  'mediator', 'chaplin/models/collection', 'models/like'
], (mediator, Collection, Like) ->
  'use strict'

  class Likes extends Collection
    model: Like

    initialize: ->
      super

      @initDeferred()

      @subscribeEvent 'login', @fetch
      @subscribeEvent 'logout', @logout

      @fetch()

    # Custom fetch function since the Facebook graph is not
    # a REST/JSON API which might be accessed using Ajax
    fetch: =>
      #console.debug 'Likes#fetch'
      user = mediator.user
      return unless user

      facebook = user.get 'provider'
      return unless facebook.name is 'facebook'

      @trigger 'loadStart'
      facebook.getInfo '/me/likes', @processLikes

    processLikes: (response) =>
      #console.debug 'Likes#processLikes', response, response.data

      # Trigger before updating the collection to hide the loading spinner
      @trigger 'load'

      # Update the collection
      @reset(if response and response.data then response.data else [])

      # Resolve the Deferred
      @resolve()

    # Handler for the global logout event
    logout: =>
      # Reset the Deferred state
      @initDeferred()
      # Empty the collection
      @reset()
