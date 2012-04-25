define [
  'mediator',
  'chaplin/models/collection',
  'models/like'
], (mediator, Collection, Like) ->
  'use strict'

  class Likes extends Collection
    model: Like

    initialize: ->
      super

      @initSyncMachine()

      @subscribeEvent 'login', @fetch
      @subscribeEvent 'logout', @logout

      @fetch()

    # Custom fetch function since the Facebook graph is not
    # a REST/JSON API which might be accessed using Ajax
    fetch: =>
      ###console.debug 'Likes#fetch'###
      user = mediator.user
      return unless user

      facebook = user.get 'provider'
      return unless facebook.name is 'facebook'

      # Switch to syncing state
      @beginSync()

      facebook.getInfo '/me/likes', @processLikes

    processLikes: (response) =>
      ###console.debug 'Likes#processLikes', response, response.data###
      return if @disposed

      # Update the collection
      @reset(if response and response.data then response.data else [])

      # Switch to synced state
      @finishSync()

    # Handler for the global logout event
    logout: =>
      # Empty the collection
      @reset()

      # Return to unsynced state
      @unsync()
