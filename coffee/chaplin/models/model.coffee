define [
  'underscore',
  'backbone',
  'chaplin/lib/subscriber'
], (_, Backbone, Subscriber) ->
  'use strict'

  class Model extends Backbone.Model

    # Mixin a Subscriber
    _(Model.prototype).extend Subscriber

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
      #console.debug 'Model#dispose', this

      # Fire an event to notify associated collections and views
      @trigger 'dispose', this

      # Unbind all global event handlers
      @unsubscribeAllEvents()

      # Remove all event handlers
      @off()

      # Remove the collection reference and attributes
      properties = [
        'collection', 'attributes', '_escapedAttributes', '_previousAttributes',
        '_silent', '_pending'
      ]
      delete this[prop] for prop in properties

      # Finished
      #console.debug 'Model#dispose', this, 'finished'
      @disposed = true

      # Your're frozen when your heart’s not open
      Object.freeze? this
