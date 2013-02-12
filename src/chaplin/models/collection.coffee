'use strict'

_ = require 'underscore'
Backbone = require 'backbone'
EventBroker = require 'chaplin/lib/event_broker'
Strategist = require 'chaplin/lib/strategist'
Model = require 'chaplin/models/model'
utils = require 'chaplin/lib/utils'

# Abstract class which extends the standard Backbone collection
# in order to add some functionality
module.exports = class Collection extends Backbone.Collection

  # Mixin an EventBroker
  _(@prototype).extend EventBroker

  # Asynchronous request strategy
  # See more information in lib/strategist.
  strategy:
    sync:
      read: 'abort'
      create: 'stack'
      update: 'stack'
      patch: 'stack'
      delete: 'abort'

    dispose:
      read: 'abort'
      create: 'null'
      update: 'null'
      patch: 'null'
      delete: 'null'

  # Use the Chaplin model per default, not Backbone.Model
  model: Model

  constructor: ->
    # Call Backbone’s constructor
    super

    # Initialize the strategist.
    @initStrategist() if @strategy

  # Initialize a strategist.
  initStrategist: ->
    @strategist = new Strategist {@strategy}

  # Mixin a Deferred
  initDeferred: ->
    _(this).extend $.Deferred()

  # Serializes collection
  serialize: ->
    @map utils.serialize

  # Adds a collection atomically, i.e. throws no event until
  # all members have been added
  addAtomic: (models, options = {}) ->
    return unless models.length
    options.silent = true
    direction = if typeof options.at is 'number' then 'pop' else 'shift'
    while model = models[direction]()
      @add model, options
    @trigger 'reset'

  sync: (method, model, options) ->
    # Invoke the before handler.
    @strategist.trigger "sync:#{method}:before", options

    # Call backbone's sync method.
    request = super

    # Invoke the after handler.
    request = @strategist.trigger "sync:#{method}:after", request

    # Return the request
    request

  # Disposal
  # --------

  disposed: false

  dispose: ->
    return if @disposed

    # Fire an event to notify associated views
    @trigger 'dispose', this

    # Dispose of the strategist; fires off disposal event.
    @strategist.dispose()
    delete @strategist

    # Empty the list silently, but do not dispose all models since
    # they might be referenced elsewhere
    @reset [], silent: true

    # Unbind all global event handlers
    @unsubscribeAllEvents()

    # Unbind all referenced handlers.
    @stopListening()

    # Remove all event handlers on this module
    @off()

    # If the model is a Deferred, reject it
    # This does nothing if it was resolved before
    @reject?()

    # Remove model constructor reference, internal model lists
    # and event handlers
    properties = [
      'model',
      'models', '_byId', '_byCid',
      '_callbacks'
    ]
    delete this[prop] for prop in properties

    # Finished
    @disposed = true

    # You’re frozen when your heart’s not open
    Object.freeze? this
