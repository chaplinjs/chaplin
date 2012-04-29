define [
  'controllers/application_controller',
  'models/navigation',
  'views/navigation_view'
], (ApplicationController, Navigation, NavigationView) ->

  'use strict'

  class NavigationController extends ApplicationController

    initialize: ->
      super
      ###console.debug 'NavigationController#initialize'###
      @navigation = new Navigation()
      @view = new NavigationView model: @navigation
