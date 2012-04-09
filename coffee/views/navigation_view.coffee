define [
  'chaplin/views/view', 'text!templates/navigation.hbs'
], (View, template) ->
  'use strict'

  class NavigationView extends View
    # This is a workaround.
    # In the end you might want to used precompiled templates.
    template: template

    id: 'navigation'
    containerSelector: '#navigation-container'
    autoRender: true

    initialize: ->
      super
      #console.debug 'NavigationView#initialize'
      @subscribeEvent 'startupController', @render
