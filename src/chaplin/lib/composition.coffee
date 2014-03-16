'use strict'

_ = require 'underscore'
Backbone = require 'backbone'
EventBroker = require 'chaplin/lib/event_broker'

has = Object::hasOwnProperty

# Composition
# -----------

# A composition governs one or more objects and stores their initialization
# options. It allows to check whether the objects can be reused by comparing
# the options.

module.exports = class Composition
  # Borrow the static extend method from Backbone.
  @extend = Backbone.Model.extend

  # Mixin Backbone events and EventBroker.
  _.extend @prototype, Backbone.Events
  _.extend @prototype, EventBroker

  # The object that is managed.
  object: null

  # The options that this composition was constructed with.
  # options: Object

  # Whether this composition is currently stale.
  _stale: false

  constructor: (options) ->
    @options = _.extend {}, options if options?
    @initialize @options

  initialize: ->
    # Empty per default.

  create: (options) ->
    # Empty per default.

  # The check method determines whether the object can be reused.
  # Per default, the new options are compared which the previous options.
  # If the check fails, the composition is recreated.
  check: (options) ->
    _.isEqual @options, options

  # Gets or sets the state status.
  # Without arguments, returns the stale status.
  # With a boolean argument, marks all applicable objects as (not) stale.
  stale: (value) ->
    # Return the current property if not requesting a change.
    return @_stale unless value?

    # Sets the stale property for every object in the composition that has it.
    @_stale = value
    for own prop, object of this when object and has.call(object, 'stale')
      object.stale = value

    # Return nothing.
    return

  # Disposal
  # --------

  disposed: false

  dispose: ->
    return if @disposed

    @unsubscribeAllEvents()

    # Unbind all referenced handlers.
    @stopListening()

    # Dispose and delete all members which are disposable.
    for own prop, object of this
      if object and typeof object.dispose is 'function'
        object.dispose()
        delete this[prop]

    # Unbind handlers of global events.
    # Remove properties which are not disposable.
    properties = ['options']
    delete this[prop] for prop in properties

    # Finished.
    @disposed = true

    # You're frozen when your heart’s not open.
    Object.freeze? this
