'use strict'

_ = require 'underscore'
Backbone = require 'backbone'
EventBroker = require 'chaplin/lib/event_broker'
Model = require 'chaplin/models/model'
utils = require 'chaplin/lib/utils'

# Abstract class which extends the standard Backbone collection
# in order to add some functionality.
module.exports = class Collection extends Backbone.Collection
  # Mixin an EventBroker.
  _.extend @prototype, EventBroker

  # Use the Chaplin model per default, not Backbone.Model.
  model: Model

  # Serializes collection.
  serialize: ->
    @map utils.serialize

  # Disposal
  # --------

  disposed: false

  dispose: ->
    return if @disposed

    # Fire an event to notify associated views.
    @trigger 'dispose', this

    # Empty the list silently, but do not dispose all models since
    # they might be referenced elsewhere.
    @reset [], silent: true

    # Unbind all global event handlers.
    @unsubscribeAllEvents()

    # Unbind all referenced handlers.
    @stopListening()

    # Remove all event handlers on this module.
    @off()

    # Remove model constructor reference, internal model lists
    # and event handlers.
    properties = [
      'model',
      'models', '_byId', '_byCid',
      '_callbacks'
    ]
    delete this[prop] for prop in properties

    # Finished.
    @disposed = true

    # You’re frozen when your heart’s not open.
    Object.freeze this
