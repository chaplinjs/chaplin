define ['lib/subscriber'], (Subscriber) ->
  'use strict'

  class Controller

    # Mixin a Subscriber
    _(Controller.prototype).extend Subscriber

    view: null
    currentId: null

    # You should set a title property and a historyURL property or method
    # on the inheriting controller class. Like this:
    # title: 'foo'
    # historyURL: 'foo'
    # historyURL: ->

    constructor: ->
      @initialize()

    initialize: ->

    #
    # Disposal
    #

    disposed: false

    dispose: =>
      return if @disposed
      #console.debug 'Controller#dispose', this

      # Dispose and delete all members which are disposable
      for own prop of this
        obj = @[prop]
        if obj and typeof obj.dispose is 'function'
          obj.dispose()
          delete @[prop]

      # Unbind handlers of global events
      @unsubscribeAllEvents()

      # Remove currentId
      properties = ['currentId']
      delete @[prop] for prop in properties

      # Finished
      #console.debug 'Controller#dispose', this, 'finished'
      @disposed = true

      # You're frozen when your heart’s not open
      Object.freeze? this
