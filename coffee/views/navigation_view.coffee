define [
  'views/view',
  'text!templates/navigation.hbs'
], (View, template) ->
  'use strict'

  class NavigationView extends View

    # Save the template string in a prototype property.
    # This is overwritten with the compiled template function.
    # In the end you might want to used precompiled templates.
    template: template
    template = null

    id: 'navigation'
    containerSelector: '#navigation-container'
    autoRender: true

    initialize: ->
      super
      #console.debug 'NavigationView#initialize'
      @subscribeEvent 'startupController', @render
