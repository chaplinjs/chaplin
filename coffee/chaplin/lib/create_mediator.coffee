define [
  'underscore',
  'backbone',
  'chaplin/lib/support'
], (_, Backbone, support) ->
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
  # The actual application-specific mediator is created in
  # /mediator.coffee using this very function.

  # Shortcut flag for proper ES5 property descriptor support
  descriptorsSupported = support.propertyDescriptors

  # The actual function which creates a mediator object
  (options = {}) ->

    _(options).defaults
      createRouterProperty: true
      createUserProperty: true

    # Wrapper for ES5 Object.defineProperty
    defineProperty = (prop, descriptor) ->
      return unless descriptorsSupported
      Object.defineProperty mediator, prop, descriptor

    # Helper method to make properties readonly and not configurable
    readonlyDescriptor =
      writable: false
      enumerable: true
      configurable: false

    readonly = ->
      return unless descriptorsSupported
      for prop in arguments
        defineProperty prop, readonlyDescriptor

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

    if options.createUserProperty

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

    # Finish
    # ------

    # Return our creation
    mediator
