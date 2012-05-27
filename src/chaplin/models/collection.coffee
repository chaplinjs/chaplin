define [
  'underscore',
  'backbone',
  'chaplin/lib/subscriber',
  'chaplin/lib/sync_machine'
  'chaplin/models/model'
], (_, Backbone, Subscriber, SyncMachine, Model) ->
  'use strict'

  # Abstract class which extends the standard Backbone collection
  # in order to add some functionality
  class Collection extends Backbone.Collection

    # Mixin a Subscriber
    _(@prototype).extend Subscriber

    # Use the Chaplin model per default, not Backbone.Model
    model: Model

    # Mixin a Deferred
    initDeferred: ->
      _(this).extend $.Deferred()

    # Mixin a synchronization state machine
    initSyncMachine: ->
      _(this).extend SyncMachine

    # Adds a collection atomically, i.e. throws no event until
    # all members have been added
    addAtomic: (models, options = {}) ->
      return unless models.length
      options.silent = true
      direction = if typeof options.at is 'number' then 'pop' else 'shift'
      while model = models[direction]()
        @add model, options
      @trigger 'reset'

    # Updates a collection with a list of models
    # Just like the reset method, but only adds new items and
    # removes items which are not in the new list.
    # Fires individual `add` and `remove` event instead of one `reset`.
    #
    # options:
    #   deep: Boolean flag to specify whether existing models
    #         should be updated with new values
    update: (models, options = {}) ->
      fingerPrint = @pluck('id').join()
      ids = _(models).pluck('id')
      newFingerPrint = ids.join()

      # Only remove if ID fingerprints differ
      if newFingerPrint isnt fingerPrint
        # Remove items which are not in the new list
        _ids = _(ids) # Underscore wrapper
        i = @models.length
        while i--
          model = @models[i]
          unless _ids.include model.id
            @remove model

      # Only add/update list if ID fingerprints differ
      # or update is deep (member attributes)
      if newFingerPrint isnt fingerPrint or options.deep
        # Add items which are not yet in the list
        for model, i in models
          preexistent = @get model.id
          if preexistent
            # Update existing model
            preexistent.set model if options.deep
          else
            # Insert new model
            @add model, at: i

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
