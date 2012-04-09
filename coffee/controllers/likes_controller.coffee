define [
  'chaplin/controllers/controller',
  'models/likes', 'models/like',
  'views/likes_view', 'views/full_like_view'
], (Controller, Likes, Like, LikesView, FullLikeView) ->
  'use strict'

  class LikesController extends Controller

    title: 'Your Likes'
    historyURL: (params) ->
      if params.id then "likes/#{params.id}" else ''

    index: (params) ->
      #console.debug 'LikesController#index'
      @likes = new Likes()
      @view = new LikesView collection: @likes

    show: (params) ->
      #console.debug 'LikesController#show'
      @like = new Like {id: params.id}, {loadDetails: true}
      @view = new FullLikeView model: @like
