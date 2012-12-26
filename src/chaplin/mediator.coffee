define [
  'underscore'
  'backbone'
  'chaplin/lib/support'
  'chaplin/lib/utils'
], (_, Backbone, support, utils) ->
  'use strict'

  # Mediator
  # --------

  # The mediator holds objects which need to be shared between modules.
  #
  # This module returns the singleton object. This is the
  # application-wide mediator you might load into modules
  # which need to talk to other modules using Publish/Subscribe.

  # Start with a simple object
  mediator = {}

  # Sealing the mediator
  # --------------------

  # After adding all needed properties, you should seal the mediator
  # using this method
  mediator.seal = ->
    # Prevent extensions and make all properties non-configurable
    if support.propertyDescriptors and Object.seal
      Object.seal mediator

  # Make the method readonly
  utils.readonly mediator, 'seal'

  # Return our creation
  mediator
