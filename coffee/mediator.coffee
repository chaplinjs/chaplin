define ['lib/support'], (support) ->
  'use strict'

  # Mediator object
  # ---------------

  # The mediator is a simple object all others modules use to
  # communicate with each other. It implements the Publish/Subscribe pattern.
  #
  # Additionally, it holds some common objects which need to be shared
  # between modules: the user and the router.
  #
  # You might store additional objects on the mediator or
  # you might introduce another object(s) as shared data storage
  # so this mediator doesn’t get the kitchen sink of your app.

  mediator = {}

  # Descriptor for readonly, non-configurable properties
  readonlyDescriptor = writable: false, configurable: false, enumerable: true
  descriptorsSupported = support.propertyDescriptors

  # Current user
  # ------------

  mediator.user = null

  # Overwrite the user property with a getter and a no-op setter.
  # The actual user is saved as a private variable.
  if descriptorsSupported
    privateUser = null
    Object.defineProperty mediator, 'user',
      get: -> privateUser
      set: -> throw new Error 'mediator.user is not writable. Use mediator.setUser.'
      enumerable: true
      configurable: false

  # Set the user from outside
  mediator.setUser = (user) ->
    if descriptorsSupported
      # Change the private variable
      privateUser = user
    else
      # Change the public property
      mediator.user = user

  # Make the setUser method readonly
  if descriptorsSupported
    Object.defineProperty mediator, 'setUser', readonlyDescriptor

  # The Router
  # ----------

  mediator.router = null

  # Include Backbone event methods for global Publish/Subscribe
  _(mediator).extend Backbone.Events

  # Initialize an empty callback list (so we might seal the object)
  mediator._callbacks  = null

  # Create Publish/Subscribe aliases
  mediator.subscribe   = mediator.on      = Backbone.Events.on
  mediator.unsubscribe = mediator.off     = Backbone.Events.off
  mediator.publish     = mediator.trigger = Backbone.Events.trigger

  # Make subscribe, unsubscribe and publish properties readonly
  if descriptorsSupported
    Object.defineProperties mediator,
      subscribe: readonlyDescriptor
      unsubscribe: readonlyDescriptor
      publish: readonlyDescriptor

  # Finish
  # ------

  # Seal the mediator object
  # (extensible: false for the mediator, configurable: false for its properties)
  Object.seal? mediator

  # Return mediator
  mediator