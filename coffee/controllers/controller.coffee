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

    startup: ->

    #
    # Disposal
    #

    disposed: false

    dispose: =>
      return if @disposed
      #console.debug 'Controller#dispose', @

      # Dispose models, collections and views
      if @model
        @model.dispose() # Also disposes associated views
      else if @collection
        @collection.dispose() # Also disposes associated collection views
      else if @view
        @view.dispose()

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
