define ['mediator'], (mediator) ->

  'use strict'

  # Add functionality to subscribe to global Publish/Subscribe events
  # so they can be removed afterwards when disposing the object

  Subscriber =

    # The subscriptions storage
    globalSubscriptions: null

    subscribeEvent: (type, handler) ->
      @globalSubscriptions or= {}
      # Add to store
      handlers = @globalSubscriptions[type] or= []
      return if _(handlers).include handler
      handlers.push handler
      # Register global handler
      mediator.subscribe type, handler, this

    unsubscribeEvent: (type, handler) ->
      return unless @globalSubscriptions
      # Remove from store
      handlers = @globalSubscriptions[type]
      if handlers
        index = _(handlers).indexOf handler
        handlers.splice index, 1 if index > -1
        delete @globalSubscriptions[type] if handlers.length is 0
      # Remove global handler
      mediator.unsubscribe type, handler

    # Unbind all recorded global handlers
    unsubscribeAllEvents: () ->
      return unless @globalSubscriptions
      for own type, handlers of @globalSubscriptions
        for handler in handlers
          # Remove global handler
          mediator.unsubscribe type, handler
      # Clear store
      @globalSubscriptions = null
