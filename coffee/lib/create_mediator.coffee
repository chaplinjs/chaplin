define ['lib/support'], (support) ->
  'use strict'

  # Mediator constructor
  # --------------------

  # The mediator is a simple object all others modules use to
  # communicate with each other. It implements the Publish/Subscribe pattern.
  #
  # Additionally, it holds two common objects which need to be shared
  # between modules: the user and the router.
  #
  # You might store additional objects on the mediator or
  # you might introduce another object(s) as shared data storage
  # so this mediator doesn’t get the kitchen sink of your app.
  #
  # This module return a method which creates a mediator.
  # The actual application-wide mediator instance is created in
  # another module using this very function, see /mediator.coffee.
  # This separation is due to testability.

  # Shortcut flag for proper ES5 property descriptor support
  descriptorsSupported = support.propertyDescriptors

  # The actual function which creates a mediator object
  createMediator = ->

    # Wrapper for ES5 Object.defineProperty
    defineProperty = (prop, descriptor) ->
      return unless descriptorsSupported
      Object.defineProperty mediator, prop, descriptor

    # Helper method to make properties readonly
    readonly = ->
      return unless descriptorsSupported
      for prop in arguments
        descriptor = Object.getOwnPropertyDescriptor mediator, prop
        descriptor.writable = false
        defineProperty prop, descriptor

    # Start with a simple object
    mediator = {}

    # Publish / Subscribe
    # -------------------

    # Mixin event methods from Backbone.Events,
    # create Publish/Subscribe aliases
    mediator.subscribe   = mediator.on      = Backbone.Events.on
    mediator.unsubscribe = mediator.off     = Backbone.Events.off
    mediator.publish     = mediator.trigger = Backbone.Events.trigger

    # Initialize an empty callback list so we might seal the mediator
    mediator._callbacks = null

    # Make subscribe, unsubscribe and publish properties readonly
    readonly 'subscribe', 'unsubscribe', 'publish'

    # Current user
    # ------------

    mediator.user = null

    # In browsers which support ECMAScript 5 property descriptors,
    # the user property is not writable directly.
    # For setting the user, you need to use the `setUser` method.

    # Overwrite the property with a getter and a no-op setter.
    # The actual value is saved as a private variable.
    privateUser = null
    defineProperty 'user',
      get: -> privateUser
      set: -> throw new Error 'mediator.user is not writable directly. ' +
        'Please use mediator.setUser instead.'
      enumerable: true
      configurable: false

    # Set the value from the outside
    mediator.setUser = (user) ->
      if descriptorsSupported
        # Change the private variable
        privateUser = user
      else
        # Change the public property
        mediator.user = user

    # Make the setUser method read-only
    readonly 'setUser'

    # The Router
    # ----------

    mediator.router = null

    # In browsers which support ECMAScript 5 property descriptors,
    # the router property is not writable directly.
    # For setting the router, you need to use the `setRouter` method.
    # Additionally, the router may only be set once.

    # Overwrite the property with a getter and a no-op setter.
    # The actual value is saved as a private variable.
    privateRouter = null
    defineProperty 'router',
      get: -> privateRouter
      set: -> throw new Error 'mediator.router is not writable directly. ' +
        'Please use mediator.setRouter instead.'
      enumerable: true
      configurable: false

    # Set the value from the outside
    mediator.setRouter = (router) ->
      # Allow the property to be set only once
      if mediator.router
        throw new Error 'mediator.router was already set, ' +
          'it can only be set once.'
      if descriptorsSupported
        # Change the private variable
        privateRouter = router
      else
        # Change the public property
        mediator.router = router

    # Finish
    # ------

    # Seal the mediator object (extensible: false for the mediator,
    # configurable: false for its properties)
    if descriptorsSupported and Object.seal
      Object.seal mediator

    # Return our creation
    mediator

  # Return the constructor functoin
  createMediator
