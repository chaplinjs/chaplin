define ['lib/create_mediator'], (createMediator) ->
  'use strict'

  # Mediator singleton
  # ------------------

  # The mediator is a simple object all others modules use to
  # communicate with each other. It implements the Publish/Subscribe pattern.
  #
  # Additionally, it holds two common objects which need to be shared
  # between modules: the user and the router.
  #
  # This module returns the mediator singleton object. This is the
  # application-wide mediator you might load into modules
  # which need to talk to other modules using Publish/Subscribe.
  #
  # The actual creation of the mediator takes place in another
  # module, see lib/create_mediator.coffee. This separation is due
  # to testability.

  # Return a mediator created by the createMediator function
  createMediator()