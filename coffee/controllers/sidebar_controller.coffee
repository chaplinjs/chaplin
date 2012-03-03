define [
  'controllers/controller', 'views/sidebar_view'
], (Controller, SidebarView) ->

  'use strict'

  class NavigationController extends Controller

    initialize: ->
      @view = new SidebarView()

