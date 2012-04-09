define [
  'controllers/controller', 'models/navigation', 'views/navigation_view'
], (Controller, Navigation, NavigationView) ->

  'use strict'

  class NavigationController extends Controller

    initialize: ->
      super
      #console.debug 'NavigationController#initialize'
      @navigation = new Navigation()
      @view = new NavigationView model: @navigation
