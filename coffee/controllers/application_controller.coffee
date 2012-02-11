define ['controllers/controller', 'views/application_view', 'controllers/navigation_controller', 'controllers/sidebar_controller'], (Controller, ApplicationView, NavigationController, SidebarController) ->

  'use strict'

  class ApplicationController extends Controller

    startup: ->
      @startupApplication()
      @startupSidebars()

    startupApplication: ->
      new ApplicationView()

    startupSidebars: ->

      navigationController = new NavigationController()
      navigationController.startup()

      sidebarController = new SidebarController()
      sidebarController.startup()

