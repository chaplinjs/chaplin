define ['lib/subscriber'], (Subscriber) ->
  'use strict'

  # Abstract class which extends the standard Backbone collection
  # in order to add some functionality
  class Collection extends Backbone.Collection
    # Mixin a Subscriber
    _(Collection.prototype).defaults Subscriber

    #initialize: ->
      #super
      # TODO: Remove an item if a 'dispose' events bubbles and
      # it wasn't removed before?

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
            preexistent.set model
          else
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

      # Finished
      @disposed = true

      # Your're frozen when your heart’s not open
      Object.freeze? this
