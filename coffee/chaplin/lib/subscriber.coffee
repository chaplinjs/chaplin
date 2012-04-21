define ['mediator'], (mediator) ->
  'use strict'

  # Add functionality to subscribe to global Publish/Subscribe events
  # so they can be removed afterwards when disposing the object.
  #
  # Mixin this object to add the subscriber capability to any object:
  # _(object).extend Subscriber
  # Or to a prototype of a class:
  # _(@prototype).extend Subscriber
  #
  # Since Backbone 0.9.2 this abstraction just serves the purpose
  # that a handler cannot be registered twice for the same event.

  Subscriber =

    subscribeEvent: (type, handler) ->
      if typeof type isnt 'string'
        throw new TypeError 'Subscriber#subscribeEvent: ' +
          'type argument must be a string'
      if typeof handler isnt 'function'
        throw new TypeError 'Subscriber#subscribeEvent: ' +
          'handler argument must be a function'

      # Ensure that a handler isn’t registered twice
      mediator.unsubscribe type, handler, @

      # Register global handler, force context to the subscriber
      mediator.subscribe type, handler, @

    unsubscribeEvent: (type, handler) ->
      if typeof type isnt 'string'
        throw new TypeError 'Subscriber#unsubscribeEvent: ' +
          'type argument must be a string'
      if typeof handler isnt 'function'
        throw new TypeError 'Subscriber#unsubscribeEvent: ' +
          'handler argument must be a function'

      # Remove global handler
      mediator.unsubscribe type, handler

    # Unbind all global handlers
    unsubscribeAllEvents: ->
      # Remove all handlers with a context of this subscriber
      mediator.unsubscribe null, null, @

  Object.freeze? Subscriber

  Subscriber