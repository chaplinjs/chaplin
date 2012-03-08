define [
  'controllers/controller', 'models/navigation', 'views/navigation_view'
], (Controller, Navigation, NavigationView) ->

  'use strict'

  class NavigationController extends Controller
    initialize: ->
      super
      @model = new Navigation()
      @view = new NavigationView model: @model
