define [
  'controllers/controller', 'models/likes', 'models/like',
  'views/likes_view', 'views/full_like_view'
], (Controller, Likes, Like, LikesView, FullLikeView) ->

  'use strict'

  class LikesController extends Controller

    historyURL: (params) ->
      if params.id then "likes/#{params.id}" else ''
      
    index: (params) ->
      #console.debug 'LikesController#index'
      @collection = new Likes()
      @view = new LikesView collection: @collection

    show: (params) ->
      #console.debug 'LikesController#show'
      @model = new Like { id: params.id }, { loadDetails: true }
      @view = new FullLikeView model: @model
