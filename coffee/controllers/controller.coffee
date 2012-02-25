define ['lib/subscriber'], (Subscriber) ->

  'use strict'

  class Controller

    # Mixin a Subscriber
    _(Controller.prototype).defaults Subscriber

    model: null
    collection: null
    view: null
    currentId: null

    constructor: ->
      @initialize()

    initialize: ->

    #
    # Disposal
    #

    disposed: false

    dispose: =>
      return if @disposed
      #console.debug 'Controller#dispose', @

      # Dispose models, collections and views
      @model.dispose() if @model # Also disposes associated views
      @collection.dispose() if @collection # Also disposes associated views
      @view.dispose() if @view # Just in case it wasn't disposed indirectly

      # Unbind handlers of global events
      @unsubscribeAllEvents()

      # Remove model, collection and view references
      properties = 'model collection view currentId'.split(' ')
      delete @[prop] for prop in properties

      # Finished
      #console.debug 'Controller#dispose', @, 'finished'
      @disposed = true

      # Your're frozen when your heart’s not open
      Object.freeze? @
