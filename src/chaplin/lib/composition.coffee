'use strict'

_ = require 'underscore'
Backbone = require 'backbone'
EventBroker = require 'chaplin/lib/event_broker'

has = Object::hasOwnProperty

# Composition
# -----------

# A composition contains one or more objects and

module.exports = class Composition
  # Borrow the static extend method from Backbone.
  @extend = Backbone.Model.extend

  # Mixin Backbone events and EventBroker.
  _.extend @prototype, Backbone.Events
  _.extend @prototype, EventBroker

  # The object that is managed.
  object: null

  # The options that this composition was constructed with.
  options: null

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
    for name, object of this when object and has.call(object, 'stale')
      object.stale = value

    # Return nothing.
    return

  # Disposal
  # --------

  disposed: false

  dispose: ->
    return if @disposed

    # Dispose and delete all members which are disposable.
    for own prop, obj of this when obj and typeof obj.dispose is 'function'
      obj.dispose()
      delete this[prop]

    # Unbind handlers of global events.
    @unsubscribeAllEvents()

    # Unbind all referenced handlers.
    @stopListening()

    # Remove properties which are not disposable.
    properties = ['redirected']
    delete this[prop] for prop in properties

    # Finished.
    @disposed = true

    # You're frozen when your heart’s not open.
    Object.freeze? this
