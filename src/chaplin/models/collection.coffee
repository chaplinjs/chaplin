define [
  'underscore'
  'backbone'
  'chaplin/lib/event_broker'
  'chaplin/lib/utils'
  'chaplin/models/model'
], (_, Backbone, EventBroker, utils, Model) ->
  'use strict'

  # Abstract class which extends the standard Backbone collection
  # in order to add some functionality
  class Collection extends Backbone.Collection

    # Mixin an EventBroker
    _(@prototype).extend EventBroker

    # Use the Chaplin model per default, not Backbone.Model
    model: Model

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

    # Disposal
    # --------

    disposed: false

    dispose: ->
      return if @disposed

      # Fire an event to notify associated views
      @trigger 'dispose', this

      # Empty the list silently, but do not dispose all models since
      # they might be referenced elsewhere
      @reset [], silent: true

      # Unbind all global event handlers
      @unsubscribeAllEvents()

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
