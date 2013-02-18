'use strict'

_ = require 'underscore'
Backbone = require 'backbone'
utils = require 'chaplin/lib/utils'
Composition = require 'chaplin/lib/composition'
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
    # Initialize collections.
    @compositions = {}

    # Subscribe to events.
    @subscribeEvent '!composer:compose', @compose
    @subscribeEvent '!composer:retrieve', @retrieve
    @subscribeEvent 'startupController', @cleanup

  # Constructs a composition and composes into the active compositions.
  # This function has several forms as described below:
  #
  # a) compose('name', Class[, options])
  #    Composes a class object. The options are passed to the class when
  #    an instance is contructed and are further used to test if the
  #    composition should be re-composed.
  #
  # b) compose('name', function)
  #    Composes a function that executes in the context of the controller;
  #    do NOT bind the function context.
  #
  # c) compose('name', options, function)
  #    Composes a function that executes in the context of the controller;
  #    do NOT bind the function context and is passed the options as a
  #    parameter. The options are further used to test if the composition
  #    should be recomposed.
  #
  # d) compose('name', options)
  #    Gives control over the composition process; the compose method of
  #    the options hash is executed in place of the function of form (c) and
  #    the check method is called (if present) to determine re-composition (
  #    otherwise this is the same as form [c]).
  #
  # e) compose('name', CompositionClass[, options])
  #    Gives complete control over the composition process.
  #
  compose: (name, second, third) ->
    # Normalize the arguments
    # If the second parameter is a function we know it is (a) or (b).
    if typeof second is 'function'
      # This is form (a) or (e) with the optional options hash if the third
      # is an obj or the second parameter's prototype has a dispose method
      if third or second::dispose
        # If the class is a Composition class then it is form (e).
        if second.prototype instanceof Composition
          return @_compose name, composition: second, options: third
        else
          return @_compose name, options: third, compose: ->
            # The compose method here just constructs the class.
            @item = new second @options

            # Render this item if it has a render method and it either
            # doesn't have an autoRender property or that autoRender
            # property is false
            autoRender = @item.autoRender
            disabledAutoRender = autoRender is undefined or not autoRender
            if disabledAutoRender and typeof @item.render is 'function'
              @item.render()

      # This is form (b).
      return @_compose name, compose: second

    # If the third parameter exists and is a function this is (c).
    if typeof third is 'function'
      return @_compose name, compose: third, options: second

    # This must be form (d).
    return @_compose name, second

  _compose: (name, options) ->
    # Assert for programmer errors
    if typeof options.compose isnt 'function' and not options.composition?
      throw new Error "compose was used incorrectly"

    if options.composition?
      # Use the passed composition directly
      composition = new options.composition options.options
    else
      # Create the composition and apply the methods (if available)
      composition = new Composition options.options
      composition.compose = options.compose
      composition.check = options.check if options.check

    # Check for an existing composition
    current = @compositions[name]

    # Apply the check method
    if current and current.check composition.options
      # Mark the current composition as not stale
      current.stale false
    else
      # Remove the current composition and apply this one
      current.dispose() if current
      composition.compose composition.options
      composition.stale false
      @compositions[name] = composition

    # Return the active composition
    @compositions[name]

  # Retrieves an active composition using the compose method and a passed
  # callback.
  retrieve: (name, callback) ->
    active = @compositions[name]
    item = (if active and not active.stale() then active.item else undefined)
    callback item

  # Declare all compositions as stale and remove all that were previously
  # marked stale without being re-composed.
  cleanup: ->
    # Action method is done; perform post-action clean up
    # Dispose and delete all no-longer-active compositions.
    # Declare all active compositions as de-activated (eg. to be removed
    # on the next controller startup unless they are re-composed).
    for name, composition of @compositions
      if composition.stale()
        composition.dispose()
        delete @compositions[name]
      else
        composition.stale true

    # Return nothing.
    return

  dispose: ->
    return if @disposed

    # Unbind handlers of global events
    @unsubscribeAllEvents()

    # Dispose of all compositions and their items (that can be)
    composition.dispose() for name, composition of @compositions

    # Remove properties
    delete @compositions

    # Finished
    @disposed = true

    # You’re frozen when your heart’s not open
    Object.freeze? this
