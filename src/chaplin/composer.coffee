'use strict'

_ = require 'underscore'
Backbone = require 'backbone'
utils = require 'chaplin/lib/utils'
EventBroker = require 'chaplin/lib/event_broker'

# Composer
# --------

# The sole job of the composer is to allow views to be 'composed'.
#
# If the view has already been composed by a previous action then nothing
# apart from registering the view as in use happens. Else, the view
# is instantiated and passed the options that were passed in. If an action
# is routed to where a view that was composed is not re-composed, the
# composed view is disposed.

module.exports = class Composer
  # Borrow the static extend method from Backbone
  @extend = Backbone.Model.extend

  # Mixin an EventBroker
  _(@prototype).extend EventBroker

  # The collection of composed compositions
  compositions: null

  constructor: ->
    @initialize arguments...

  initialize: (options = {}) ->
    # initialize collections
    @compositions = {}

    # subscribe to events
    @subscribeEvent '!composer:compose', @compose
    @subscribeEvent 'startupController', @onStartupController

  perform: (type, options) ->
    # Build the composition; this is the function
    # that is overidden when the `compose` option is passed to the
    # compose function
    composition =
      params: options.params
      view: new type options

    # If the view is not automatically rendered; render it
    # The composing controller has no idea if and when it should render
    composition.view.render() unless composition.view.autoRender

    # Return our composition
    composition

  stale: (composition, value) ->
    # Set the stale property on the composition
    composition.stale = value

    # Sets the stale property for every item in the composition that has it
    for name, item of composition when _(item).has 'stale'
      item.stale = value

    # Don't bother to return the for loop
    return

  compose: (name, type, options = {}) ->
    # Short form (view-class, ctor-options) or long form ?
    if arguments.length is 3 or typeof type is 'function'
      # Assume short form; apply functions
      options.params = _(options).clone()
      options.compose = (options) => @perform type, options

    else
      # Long form; first argument are the options
      options = type

    # Assert for programmer errors
    unless typeof options.compose is 'function'
      throw new Error "options#compose must be defined"

    unless typeof options.check is 'function'
      options.check = -> true  # By default; we never re-compose

    # Attempt to find an active composition that matches
    composition = @compositions[name]

    if composition isnt undefined and options.check.call(composition, options.params)
      # We have an active composition; declare composition as not stale so
      # that its regions will now be counted
      @stale composition, false

    else
      # Dispose of the old composition
      @destroy composition if composition isnt undefined

      # Perform the composition and append to the list so we can
      # track its lifetime
      @compositions[name] = options.compose options.params

  destroy: (composition) ->
    # Dispose of everything that can be disposed
    for name, item of composition when typeof item?.dispose is 'function'
      item.dispose()
      delete composition[name]

    # Don't bother to return the for loop
    return

  onStartupController: (options) ->
    # Action method is done; perform post-action clean up
    # Dispose and delete all unactive compositions
    # Declare all active compositions as de-activated
    for name, composition of @compositions
      if composition.stale
        @destroy composition
        delete @compositions[name]
      else
        @stale composition, true

  dispose: ->
    return if @disposed

    # Unbind handlers of global events
    @unsubscribeAllEvents()

    # Dispose of all compositions and their items (that can be)
    @destroy composition for name, composition of @compositions

    # Remove properties
    delete @compositions

    # Finished
    @disposed = true

    # You’re frozen when your heart’s not open
    Object.freeze? this
