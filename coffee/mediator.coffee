define ->
  'use strict'

  # The mediator is the objects all others modules use to
  # communicate with each other.
  # It implements the Publish/Subscribe pattern.

  mediator = {}

  # Current user
  mediator.user = null

  # The router
  mediator.router = null

  # Include Backbone event methods for
  # global Publish/Subscribe
  _(mediator).defaults Backbone.Events

  # Initialize an empty callback list (so we might seal the object)
  mediator._callbacks  = null

  # Create Publish/Subscribe aliases
  mediator.subscribe   = mediator.on      = Backbone.Events.on
  mediator.unsubscribe = mediator.off     = Backbone.Events.off
  mediator.publish     = mediator.trigger = Backbone.Events.trigger

  # Make subscribe, unsubscribe and publish properties readonly
  if Object.defineProperties
    desc = writable: false
    Object.defineProperties mediator,
      subscribe: desc, unsubscribe: desc, publish: desc

  # Seal the mediator object
  # (extensible: false for the mediator, configurable: false for its properties)
  Object.seal? mediator

  # Return mediator
  mediator