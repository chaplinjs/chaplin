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
      ###console.debug 'Collection#update', 'deep?', options.deep###

      fingerPrint = @pluck('id').join()
      ids = _(newList).pluck('id')
      newFingerPrint = ids.join()
      ###console.debug '\t' + fingerPrint + '\n\t' + newFingerPrint + '\n\t' + (fingerPrint is newFingerPrint)###

      # Only execute removal if ID fingerprints differ
      unless fingerPrint is newFingerPrint
        # Remove items which are not in the new list
        _ids = _(ids) # Underscore wrapper

        i = @models.length - 1
        while i >= 0
          model = @models[i]
          unless _ids.include model.id
            ###console.debug '\tremove', model.id###
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
            ###console.debug '\update', preexistent.id###
            preexistent.set model
          else
            ###console.debug '\tinsert', model.id, 'at', i###
            @add model, at: i

    # Disposal
    # --------

    disposed: false

    dispose: ->
      return if @disposed
      ###console.debug 'Collection#dispose', this###

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
      ###console.debug 'Collection#dispose', this, 'finished'###
      @disposed = true

      # Your're frozen when your heart’s not open
      Object.freeze? this
