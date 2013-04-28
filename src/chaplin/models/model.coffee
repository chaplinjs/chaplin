'use strict'

_ = require 'underscore'
Backbone = require 'backbone'
utils = require 'chaplin/lib/utils'
EventBroker = require 'chaplin/lib/event_broker'

# Private helper function for serializing attributes recursively,
# creating objects which delegate to the original attributes
# in order to protect them from changes.
serializeAttributes = (model, attributes, modelStack) ->
  # Create a delegator object.
  delegator = utils.beget attributes

  # Add model to stack.
  modelStack ?= {}
  modelStack[model.cid] = true

  # Map model/collection to their attributes. Create a property
  # on the delegator that shadows the original attribute.
  for key, value of attributes

    # Handle models.
    if value instanceof Backbone.Model
      delegator[key] = serializeModelAttributes value, model, modelStack

    # Handle collections.
    else if value instanceof Backbone.Collection
      serializedModels = []
      for otherModel in value.models
        serializedModels.push(
          serializeModelAttributes(otherModel, model, modelStack)
        )
      delegator[key] = serializedModels

  # Remove model from stack.
  delete modelStack[model.cid]

  # Return the delegator.
  delegator

# Serialize the attributes of a given model
# in the context of a given tree.
serializeModelAttributes = (model, currentModel, modelStack) ->
  # Nullify circular references.
  return null if model is currentModel or _.has modelStack, model.cid
  # Serialize recursively.
  attributes = if typeof model.getAttributes is 'function'
    # Chaplin models.
    model.getAttributes()
  else
    # Backbone models.
    model.attributes
  serializeAttributes model, attributes, modelStack


# Abstraction that adds some useful functionality to backbone model.
module.exports = class Model extends Backbone.Model
  # Mixin an EventBroker.
  _.extend @prototype, EventBroker

  # This method is used to get the attributes for the view template
  # and might be overwritten by decorators which cannot create a
  # proper `attributes` getter due to ECMAScript 3 limits.
  getAttributes: ->
    @attributes

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

    # Fire an event to notify associated collections and views.
    @trigger 'dispose', this

    # Unbind all global event handlers.
    @unsubscribeAllEvents()

    # Unbind all referenced handlers.
    @stopListening()

    # Remove all event handlers on this module.
    @off()

    # Remove the collection reference, internal attribute hashes
    # and event handlers.
    properties = [
      'collection',
      'attributes', 'changed'
      '_escapedAttributes', '_previousAttributes',
      '_silent', '_pending',
      '_callbacks'
    ]
    delete this[prop] for prop in properties

    # Finished.
    @disposed = true

    # You’re frozen when your heart’s not open.
    Object.freeze? this
