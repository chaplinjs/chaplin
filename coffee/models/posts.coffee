define [
  'mediator', 'models/collection', 'models/post'
], (mediator, Collection, Post) ->

  'use strict'

  class Posts extends Collection

    model: Post

    initialize: ->
      super

      # Mixin a Deferred
      _(this).extend $.Deferred()

      @getPosts()
      @subscribeEvent 'login', @getPosts
      @subscribeEvent 'logout', @reset

    getPosts: ->
      #console.debug 'Posts#getPosts'

      user = mediator.user
      return unless user

      provider = user.get 'provider'
      return unless provider.name is 'facebook'

      @trigger 'loadStart'
      provider.getInfo '/158352134203230/feed', @processPosts

    processPosts: (response) =>
      #console.debug 'Posts#processPosts', response, response.data

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
