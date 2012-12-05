define [
  'underscore'
  'backbone'
  'chaplin/lib/event_broker'
], (_, Backbone, EventBroker) ->
  'use strict'

  class Controller

    # Borrow the static extend method from Backbone
    @extend = Backbone.Model.extend

    # Mixin an EventBroker
    _(@prototype).extend EventBroker

    view: null
    currentId: null

    # Internal flag which stores whether `redirectTo`
    # was called in the current action
    redirected: false

    # You should set a `title` property and a `historyURL` property or method
    # on the derived controller. Like this:
    # title: 'foo'
    # historyURL: 'foo'
    # historyURL: ->

    constructor: ->
      @configureBeforeFilters()
      @initialize arguments...

    initialize: ->
      # Empty per default

    # Extended before filters throughout the entire prototype chain, keeping the
    # order of the resulting object starting from the oldest ancestor
    configureBeforeFilters: ->
      parentBeforeFilters = @constructor.__super__?.configureBeforeFilters?() or {}
      @before = _.extend _.clone(parentBeforeFilters), @before

    # Redirection
    # -----------

    redirectTo: (arg1, action, params, options) ->
      @redirected = true
      if arguments.length is 1
        # URL was passed, try to route it
        @publishEvent '!router:route', arg1, {}, (routed) ->
          unless routed
            throw new Error 'Controller#redirectTo: no route matched'
      else
        # Assume controller and action names were passed
        @publishEvent '!startupController', arg1, action, params, options

    # Disposal
    # --------

    disposed: false

    dispose: ->
      return if @disposed

      # Dispose and delete all members which are disposable
      for own prop of this
        obj = this[prop]
        if obj and typeof obj.dispose is 'function'
          obj.dispose()
          delete this[prop]

      # Unbind handlers of global events
      @unsubscribeAllEvents()

      # Remove properties which are not disposable
      properties = ['currentId', 'redirected']
      delete this[prop] for prop in properties

      # Finished
      @disposed = true

      # You're frozen when your heart’s not open
      Object.freeze? this
