define [
  'mediator', 'models/collection', 'models/like'
], (mediator, Collection, Like) ->
  'use strict'

  class Likes extends Collection
    model: Like

    initialize: ->
      super

      # Mixin a Deferred
      _(this).extend $.Deferred()

      @getLikes()
      @subscribeEvent 'login', @getLikes
      @subscribeEvent 'logout', @reset

    getLikes: ->
      user = mediator.user
      return unless user

      provider = user.get 'provider'
      return unless provider.name is 'facebook'

      @trigger 'loadStart'
      provider.getInfo '/me/likes', @processLikes

    processLikes: (response) =>
      # Trigger before updating the collection to hide the loading spinner
      @trigger 'load'

      # Update the collection
      @reset(if response and response.data then response.data else [])

      # Resolve the Deferred
      @resolve()
