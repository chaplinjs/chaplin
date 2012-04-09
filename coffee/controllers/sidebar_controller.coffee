define [
  'chaplin/controllers/controller',
  'views/sidebar_view'
], (Controller, SidebarView) ->
  'use strict'

  class SidebarController extends Controller

    initialize: ->
      @view = new SidebarView()

