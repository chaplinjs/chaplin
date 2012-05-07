define [
  'underscore',
  'backbone',
  'chaplin/lib/subscriber',
  'chaplin/lib/sync_machine'
  'chaplin/models/model'
], (_, Backbone, Subscriber, SyncMachine, ChaplinModel) ->
  'use strict'

  # Abstract class which extends the standard Backbone collection
  # in order to add some functionality
  class ChaplinCollection extends Backbone.Collection

    # Mixin a Subscriber
    _(@prototype).extend Subscriber

    # Use the Chaplin model per default, not Backbone.Model
    model: ChaplinModel

    # Creates a new deferred and mixes it into the collection
    # This method can be called multiple times to reset the
    # status of the Deferred to 'pending'.
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
      batch_direction = if typeof options.at is 'number' then 'pop' else 'shift'
      @add(model, options) while model = models[batch_direction]()
      @trigger 'reset'

    # Updates a collection with a list
    # Just like the reset method, but only adds new items and
    # removes items which are not in the new list
    #
    # options:
    #   deep: Boolean flag to specify whether existing models should be updated
    #         with new values
    update: (newList, options = {}) ->
      fingerPrint = @pluck('id').join()
      ids = _(newList).pluck('id')
      newFingerPrint = ids.join()

      # Only execute removal if ID fingerprints differ
      unless fingerPrint is newFingerPrint
        # Remove items which are not in the new list
        _ids = _(ids) # Underscore wrapper

        i = @models.length - 1
        while i >= 0
          model = @models[i]
          unless _ids.include model.id
            @remove model
          i--

      # Only add/update list if ID fingerprints differ or update
      # is deep (member attributes)
      unless fingerPrint is newFingerPrint and not options.deep
        # Add item which are not yet in the list
        for model, i in newList
          preexistent = @get model.id
          if preexistent
            continue unless options.deep
            # Update existing model
            preexistent.set model
          else
            # Insert new model
            @add model, at: i

    # Disposal
    # --------

    disposed: false

    dispose: ->
      ###console.debug 'Collection#dispose', this, 'disposed?', @disposed###
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

      # Remove model constructor reference, internal lists and event handlers
      properties = [
        'model',
        'models', '_byId', '_byCid',
        '_callbacks'
      ]
      delete this[prop] for prop in properties

      # Finished
      @disposed = true

      # Your're frozen when your heart’s not open
      Object.freeze? this
