define [
  'backbone'
], (Backbone) ->
  'use strict'

  # Add functionality to subscribe and publish to global
  # Publish/Subscribe events so they can be removed afterwards
  # when disposing the object.
  #
  # Mixin this object to add the subscriber capability to any object:
  # _(object).extend EventBroker
  # Or to a prototype of a class:
  # _(@prototype).extend EventBroker
  #
  # Since Backbone 0.9.2 this abstraction just serves the purpose
  # that a handler cannot be registered twice for the same event.

  EventBroker =

    subscribeEvent: (type, handler) ->
      if typeof type isnt 'string'
        throw new TypeError 'EventBroker#subscribeEvent: ' +
          'type argument must be a string'
      if typeof handler isnt 'function'
        throw new TypeError 'EventBroker#subscribeEvent: ' +
          'handler argument must be a function'

      # Ensure that a handler isn’t registered twice
      Backbone.off type, handler, this

      # Register global handler, force context to the subscriber
      Backbone.on type, handler, this

    unsubscribeEvent: (type, handler) ->
      if typeof type isnt 'string'
        throw new TypeError 'EventBroker#unsubscribeEvent: ' +
          'type argument must be a string'
      if typeof handler isnt 'function'
        throw new TypeError 'EventBroker#unsubscribeEvent: ' +
          'handler argument must be a function'

      # Remove global handler
      Backbone.off type, handler

    # Unbind all global handlers
    unsubscribeAllEvents: ->
      # Remove all handlers with a context of this subscriber
      Backbone.off null, null, this

    publishEvent: (type) ->
      if typeof type isnt 'string'
        throw new TypeError 'EventBroker#publishEvent: ' +
          'type argument must be a string'

      # Publish global handler
      Backbone.trigger.apply Backbone, arguments

  # You’re frozen when your heart’s not open
  Object.freeze? EventBroker

  EventBroker
