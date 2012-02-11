define ['views/view', 'text!templates/navigation.hbs'], (View, template) ->

  'use strict'

  class NavigationView extends View

    # This is a workaround. In the end you might want to used precompiled templates.
    @template: template

    id: 'navigation'

    containerSelector: '#navigation-container'

    initialize: ->
      super
      #console.debug 'NavigationView#initialize'
      @subscribeEvent 'startupController', @render
      @render()

    render: ->
      #console.debug 'NavigationView#render', @el
      super
      
      # Append to DOM
      @$container.append @el