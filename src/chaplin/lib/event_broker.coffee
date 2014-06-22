'use strict'

mediator = require 'chaplin/mediator'

# Add functionality to subscribe and publish to global
# Publish/Subscribe events so they can be removed afterwards
# when disposing the object.
#
# Mixin this object to add the subscriber capability to any object:
# _.extend object, EventBroker
# Or to a prototype of a class:
# _.extend @prototype, EventBroker
#
# Since Backbone 0.9.2 this abstraction just serves the purpose
# that a handler cannot be registered twice for the same event.

EventBroker =
  subscribeEvent: (type, handler) ->
    # Ensure that a handler isn’t registered twice.
    mediator.unsubscribe type, handler, this

    # Register global handler, force context to the subscriber.
    mediator.subscribe type, handler, this

  subscribeEventOnce: (type, handler) ->
    # Ensure that a handler isn’t registered twice.
    mediator.unsubscribe type, handler, this

    # Register global handler, force context to the subscriber.
    mediator.subscribeOnce type, handler, this

  unsubscribeEvent: (type, handler) ->
    # Remove global handler.
    mediator.unsubscribe type, handler

  # Unbind all global handlers.
  unsubscribeAllEvents: ->
    # Remove all handlers with a context of this subscriber.
    mediator.unsubscribe null, null, this

  publishEvent: (type, args...) ->
    # Publish global handler.
    mediator.publish type, args...

# You’re frozen when your heart’s not open.
Object.freeze? EventBroker

# Return our creation.
module.exports = EventBroker
