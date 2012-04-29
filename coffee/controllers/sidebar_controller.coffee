define [
  'controllers/application_controller',
  'views/sidebar_view'
], (ApplicationController, SidebarView) ->
  'use strict'

  class SidebarController extends ApplicationController

    initialize: ->
      @view = new SidebarView()

