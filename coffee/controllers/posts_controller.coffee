define [
  'controllers/controller', 'models/posts', 'views/posts_view'
], (Controller, Posts, PostsView) ->
  'use strict'

  class PostsController extends Controller
    title: 'Facebook Wall Posts'
    historyURL: 'posts'

    index: (params) ->
      @collection = new Posts()
      @view = new PostsView collection: @collection
