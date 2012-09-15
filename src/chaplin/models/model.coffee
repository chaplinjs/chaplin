define [
  'underscore'
  'backbone'
  'chaplin/lib/utils'
  'chaplin/lib/event_broker'
], (_, Backbone, utils, EventBroker) ->
  'use strict'

  class Model extends Backbone.Model

    # Mixin an EventBroker
    _(@prototype).extend EventBroker

    # Mixin a Deferred
    initDeferred: ->
      _(this).extend $.Deferred()

    # This method is used to get the attributes for the view template
    # and might be overwritten by decorators which cannot create a
    # proper `attributes` getter due to ECMAScript 3 limits.
    getAttributes: ->
      @attributes

    # Private helper function for serializing attributes recursively,
    # creating objects which delegate to the original attributes
    # when a property needs to be overwritten.
    serializeAttributes = (model, attributes, modelStack) ->
      # Create a delegator on initial call
      unless modelStack
        delegator = utils.beget attributes
        modelStack = [model]
      else
        # Add model to stack
        modelStack.push model
      # Map model/collection to their attributes
      for key, value of attributes
        if value instanceof Backbone.Model
          # Don’t change the original attribute, create a property
          # on the delegator which shadows the original attribute
          delegator ?= utils.beget attributes
          delegator[key] = if value is model or value in modelStack
            # Nullify circular references
            null
          else
            # Serialize recursively
            serializeAttributes(
              value, value.getAttributes(), modelStack
            )
        else if value instanceof Backbone.Collection
          delegator ?= utils.beget attributes
          delegator[key] = for item in value.models
            serializeAttributes(
              item, item.getAttributes(), modelStack
            )

      # Remove model from stack
      modelStack.pop()
      # Return the delegator if it was created, otherwise the plain attributes
      delegator or attributes

    # Return an object which delegates to the attributes
    # (i.e. an object which has the attributes as prototype)
    # so primitive values might be added and altered safely.
    # Map models to their attributes, recursively.
    serialize: ->
      serializeAttributes this, @getAttributes()

    # Disposal
    # --------

    disposed: false

    dispose: ->
      return if @disposed

      # Fire an event to notify associated collections and views
      @trigger 'dispose', this

      # Unbind all global event handlers
      @unsubscribeAllEvents()

      # Remove all event handlers on this module
      @off()

      # If the model is a Deferred, reject it
      # This does nothing if it was resolved before
      @reject?()

      # Remove the collection reference, internal attribute hashes
      # and event handlers
      properties = [
        'collection',
        'attributes', 'changed'
        '_escapedAttributes', '_previousAttributes',
        '_silent', '_pending',
        '_callbacks'
      ]
      delete this[prop] for prop in properties

      # Finished
      @disposed = true

      # You’re frozen when your heart’s not open
      Object.freeze? this
