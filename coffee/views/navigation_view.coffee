define [
  'views/application_view',
  'text!templates/navigation.hbs'
], (ApplicationView, template) ->
  'use strict'

  class NavigationView extends ApplicationView

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
      ###console.debug 'NavigationView#initialize'###
      @subscribeEvent 'startupController', @render
