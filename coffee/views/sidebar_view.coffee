define ['mediator', 'views/view', 'text!templates/sidebar.hbs'], (mediator, View, template) ->

  'use strict'

  class SidebarView extends View

    # This is a workaround. In the end you might want to used precompiled templates.
    @template = template

    id: 'sidebar'

    containerSelector: '#sidebar-container'

    initialize: ->
      super
      @render()
      @subscribeEvent 'loginStatus', @loginStatusHandler
      @subscribeEvent 'userData', @render

    loginStatusHandler: (loggedIn) =>
      #console.debug 'SidebarView#loginStatusHandler', loggedIn
      if loggedIn
        @model = mediator.user
      else
        @model = null
      @render()

    render: ->
      super
      #console.debug 'SidebarView#render'

      # Append to DOM
      @$container.append @el