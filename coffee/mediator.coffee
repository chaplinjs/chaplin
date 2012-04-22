define [
  'chaplin/lib/create_mediator',
  'chaplin/lib/support'
], (createMediator, support) ->
  'use strict'

  # Mediator singleton
  # ------------------

  # The mediator is a simple object all others modules use to communicate
  # with each other. It implements the Publish/Subscribe pattern.
  #
  # Additionally, it holds objects which need to be shared between modules.
  # In this case, a `user` property is created for getting the user object
  # and a `createUser` method for setting the user.
  #
  # This module returns the singleton object. This is the
  # application-wide mediator you might load into modules
  # which need to talk to other modules using Publish/Subscribe.
  #
  # The actual creation of the mediator takes place in the module
  # chaplin/lib/create_mediator.coffee.

  # Create the mediator using Chaplin’s constructor.
  mediator = createMediator
    # Add properties/methods for getting/setting the user.
    createUserProperty: true

  # Application-specific mediator properties
  # ----------------------------------------

  # You might add methods and properties to the mediator here

  #mediator.foo = ->
  
  # Finally seal the mediator
  # -------------------------

  # Prevent extensions and make all properties non-configurable
  if support.propertyDescriptors and Object.seal
    Object.seal mediator

  mediator