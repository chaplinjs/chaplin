define ['controllers/controller', 'views/sidebar_view'], (Controller, SidebarView) ->

  'use strict'

  class NavigationController extends Controller

    startup: ->
      @view = new SidebarView()

