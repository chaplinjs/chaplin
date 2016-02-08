'use strict'

_ = require 'underscore'
Backbone = require 'backbone'
EventBroker = require './event_broker'

# Composition
# -----------

# A utility class that is meant as a simple proxied version of a
# controller that is used internally to inflate simple
# calls to !composer:compose and may be extended and used to have complete
# control over the composition process.
module.exports = class Composition
  # Borrow the static extend method from Backbone.
  @extend = Backbone.Model.extend

  # Mixin Backbone events and EventBroker.
  _.extend @prototype, Backbone.Events
  _.extend @prototype, EventBroker

  # The item that is composed; this is by default a reference to this.
  item: null

  # The options that this composition was constructed with.
  options: null

  # Whether this composition is currently stale.
  _stale: false

  constructor: (options) ->
    @options = _.extend {}, options
    @item = this
    @initialize @options

  initialize: ->
    # Empty per default.

  # The compose method is called when this composition is to be composed.
  compose: ->
    # Empty per default.

  # The check method is called when this composition is asked to be
  # composed again. The passed options are the newly passed options.
  # If this returns false then the composition is re-composed.
  check: (options) ->
    _.isEqual @options, options

  # Marks all applicable items as stale.
  stale: (value) ->
    # Return the current property if not requesting a change.
    return @_stale unless value?

    # Sets the stale property for every item in the composition that has it.
    @_stale = value
    for name, item of this when (
      item and item isnt this and
      typeof item is 'object' and item.hasOwnProperty 'stale'
    )
      item.stale = value

    # Return nothing.
    return

  # Disposal
  # --------

  disposed: false

  dispose: ->
    return if @disposed

    # Dispose and delete all members which are disposable.
    for key in Object.keys this
      member = @[key]
      if member and member isnt this and
      typeof member.dispose is 'function'
        member.dispose()
        delete @[key]

    # Unbind handlers of global events.
    @unsubscribeAllEvents()

    # Unbind all referenced handlers.
    @stopListening()

    # Remove properties which are not disposable.
    delete this.redirected

    # Finished.
    @disposed = true

    # You're frozen when your heart’s not open.
    Object.freeze this
