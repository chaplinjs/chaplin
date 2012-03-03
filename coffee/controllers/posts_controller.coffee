define [
  'controllers/controller', 'models/posts', 'views/posts_view'
], (Controller, Posts, PostsView) ->

  'use strict'

  class PostsController extends Controller

    historyURL: 'posts'

    index: (params) ->
      #console.debug 'PostsController#index'
      @collection = new Posts()
      @view = new PostsView collection: @collection
