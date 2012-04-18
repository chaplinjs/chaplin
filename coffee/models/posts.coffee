define [
  'underscore',
  'mediator',
  'chaplin/models/collection',
  'models/post'
], (_, mediator, Collection, Post) ->
  'use strict'

  class Posts extends Collection
    model: Post

    initialize: ->
      super

      @initDeferred()

      @subscribeEvent 'login', @fetch
      @subscribeEvent 'logout', @logout

      @fetch()

    # Custom fetch function since the Facebook graph is not
    # a REST/JSON API which might be accessed using Ajax
    fetch: =>
      #console.debug 'Posts#fetch'
      user = mediator.user
      return unless user

      facebook = user.get 'provider'
      return unless facebook.name is 'facebook'

      @trigger 'loadStart'
      facebook.getInfo '/158352134203230/feed', @processPosts

    processPosts: (response) =>
      #console.debug 'Posts#processPosts', response, response.data
      return if @disposed

      # Trigger before updating the collection to hide the loading spinner
      @trigger 'load'

      posts = if response and response.data then response.data else []

      # Only show posts from moviepilot.com
      posts = _(posts).filter (post) ->
        post.from and post.from.name is 'moviepilot.com'

      # Update the collection
      @reset posts

      # Resolve the Deferred
      @resolve()

    # Handler for the global logout event
    logout: =>
      # Reset the Deferred state
      @initDeferred()
      # Empty the collection
      @reset()
