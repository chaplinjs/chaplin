define [
  'underscore',
  'backbone',
  'chaplin/lib/subscriber'
], (_, Backbone, Subscriber) ->
  'use strict'

  class Model extends Backbone.Model

    # Mixin a Subscriber
    _(@prototype).extend Subscriber

    # Creates a new deferred and mixes it into the model
    # This method can be called multiple times to reset the
    # status of the Deferred to 'pending'.
    initDeferred: ->
      _(this).extend $.Deferred()

    # This method is used to get the attributes for the view template
    # and might be overwritten by decorators which cannot create a
    # proper `attributes` getter due to ECMAScript 3 limits.
    getAttributes: ->
      @attributes

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

      # Remove the collection reference and attributes
      properties = [
        'collection',
        'attributes', '_escapedAttributes', '_previousAttributes',
        '_silent', '_pending',
        '_callbacks'
      ]
      delete this[prop] for prop in properties

      # Finished
      @disposed = true

      # Your're frozen when your heart’s not open
      Object.freeze? this
