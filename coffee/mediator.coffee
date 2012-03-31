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

  # Shortcut flag for proper ES5 property descriptor support
  descriptorsSupported = support.propertyDescriptors
  # Descriptor for read-only, non-configurable properties
  readonlyDescriptor = writable: false, configurable: false, enumerable: true
  # Helper method to make a property readonly
  defineProperty = (obj, prop, descriptor) ->
    if descriptorsSupported
      Object.defineProperty obj, prop, descriptor
  readonly = (obj, prop) ->
    defineProperty obj, prop, readonlyDescriptor


  # Current user
  # ------------

  mediator.user = null

  # In browsers which support ECMAScript 5 property descriptors,
  # the user property isn’t settable directly, but it’s a read-only
  # getter property. For safety, you have to use the setUser method
  # to set mediator.user

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

  # Make the setUser method read-only
  readonly mediator, 'setUser'

  # The Router
  # ----------

  mediator.router = null

  # In browsers which support ECMAScript 5 property descriptors,
  # the router might be set once with the setRouter method.
  # For safety, the router property is set to read-only
  # after it is set.

  # Set the router once
  mediator.setRouter = (router) ->
    throw new Error 'Router already set' if mediator.router
    mediator.router = router
    # Make the router property readonly
    readonly mediator, 'router'

  # Make the setRouter method readonly
  readonly mediator, 'setRouter'

  # Publish / Subscribe
  # -------------------

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