define [
  'mediator',
  'views/view',
  'text!templates/sidebar.hbs'
], (mediator, View, template) ->
  'use strict'

  class SidebarView extends View

    # Save the template string in a prototype property.
    # This is overwritten with the compiled template function.
    # In the end you might want to used precompiled templates.
    template: template
    template = null

    id: 'sidebar'
    containerSelector: '#sidebar-container'
    autoRender: true

    initialize: ->
      super

      @subscribeEvent 'loginStatus', @loginStatusHandler
      @subscribeEvent 'userData', @render

      @delegate 'click', '#logout-button', @logoutButtonClick

    loginStatusHandler: (loggedIn) =>
      #console.debug 'SidebarView#loginStatusHandler', loggedIn
      if loggedIn
        @model = mediator.user
      else
        @model = null
      @render()

    # Handle clicks on the logout button
    logoutButtonClick: (event) ->
      event.preventDefault()
      # Publish a global !logout event
      mediator.publish '!logout'
