define [
  'controllers/application_controller',
  'models/posts',
  'views/posts_view'
], (ApplicationController, Posts, PostsView) ->
  'use strict'

  class PostsController extends ApplicationController

    title: 'Facebook Wall Posts'
    historyURL: 'posts'

    index: (params) ->
      ###console.debug 'PostsController#index'###
      @posts = new Posts()
      @view = new PostsView collection: @posts
