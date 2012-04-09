define ['mediator'], (mediator) ->
  'use strict'

  # Add functionality to subscribe to global Publish/Subscribe events
  # so they can be removed afterwards when disposing the object.
  # Mixin this object to add the subscriber capability to any object.

  # TODO: Since Backbone 0.9.2, the store just serves the purpose
  # that a handler cannot be registered twice for the same event

  Subscriber =

    # The subscriptions storage
    _globalSubscriptions: null

    subscribeEvent: (type, handler) ->
      if typeof type isnt 'string'
        throw new TypeError 'Subscriber#subscribeEvent: ' +
          'type argument must be string'
      if typeof handler isnt 'function'
        throw new TypeError 'Subscriber#subscribeEvent: ' +
          'handler argument must be function'

      # Add to store
      @_globalSubscriptions or= {}
      handlers = @_globalSubscriptions[type] or= []
      # Ensure that a handler isn’t registered twice
      return if _(handlers).include handler
      handlers.push handler

      # Register global handler, force context to the subscriber
      mediator.subscribe type, handler, @

    unsubscribeEvent: (type, handler) ->
      if typeof type isnt 'string'
        throw new TypeError 'Subscriber#unsubscribeEvent: ' +
          'type argument must be string'
      if typeof handler isnt 'function'
        throw new TypeError 'Subscriber#unsubscribeEvent: ' +
          'handler argument must be function'

      # Remove from store
      return unless @_globalSubscriptions
      handlers = @_globalSubscriptions[type]
      if handlers
        index = _(handlers).indexOf handler
        handlers.splice index, 1 if index > -1
        delete @_globalSubscriptions[type] if handlers.length is 0

      # Remove global handler
      mediator.unsubscribe type, handler

    # Unbind all recorded global handlers
    unsubscribeAllEvents: ->
      # Clear store
      @_globalSubscriptions = null

      # Remove all handlers with a context of this subscriber
      mediator.unsubscribe null, null, @

  Object.freeze? Subscriber

  Subscriber