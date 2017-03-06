'use strict'

_ = require 'underscore'
Backbone = require 'backbone'

Composition = require './lib/composition'
EventBroker = require './lib/event_broker'
mediator = require './mediator'

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
  _.extend @prototype, EventBroker

  # The collection of composed compositions
  compositions: null

  constructor: ->
    @initialize arguments...

  initialize: (options = {}) ->
    # Initialize collections.
    @compositions = {}

    # Subscribe to events.
    mediator.setHandler 'composer:compose', @compose, this
    mediator.setHandler 'composer:retrieve', @retrieve, this
    @subscribeEvent 'dispatcher:dispatch', @cleanup

  # Constructs a composition and composes into the active compositions.
  # This function has several forms as described below:
  #
  # 1. compose('name', Class[, options])
  #    Composes a class object. The options are passed to the class when
  #    an instance is contructed and are further used to test if the
  #    composition should be re-composed.
  #
  # 2. compose('name', function)
  #    Composes a function that executes in the context of the controller;
  #    do NOT bind the function context.
  #
  # 3. compose('name', options, function)
  #    Composes a function that executes in the context of the controller;
  #    do NOT bind the function context and is passed the options as a
  #    parameter. The options are further used to test if the composition
  #    should be recomposed.
  #
  # 4. compose('name', options)
  #    Gives control over the composition process; the compose method of
  #    the options hash is executed in place of the function of form (3) and
  #    the check method is called (if present) to determine re-composition (
  #    otherwise this is the same as form [3]).
  #
  # 5. compose('name', CompositionClass[, options])
  #    Gives complete control over the composition process.
  #
  compose: (name, second, third) ->
    # Normalize the arguments
    # If the second parameter is a function we know it is (1) or (2).
    if typeof second is 'function'
      # This is form (1) or (5) with the optional options hash if the third
      # is an obj or the second parameter's prototype has a dispose method
      if third or second::dispose
        # If the class is a Composition class then it is form (5).
        if second.prototype instanceof Composition
          return @_compose name, composition: second, options: third
        else
          return @_compose name, options: third, compose: ->
            # The compose method here just constructs the class.
            # Model and Collection both take `options` as the second argument.
            if second.prototype instanceof Backbone.Model or
            second.prototype instanceof Backbone.Collection
              @item = new second null, @options
            else
              @item = new second @options

            # Render this item if it has a render method and it either
            # doesn't have an autoRender property or that autoRender
            # property is false
            autoRender = @item.autoRender
            disabledAutoRender = autoRender is undefined or not autoRender
            if disabledAutoRender and typeof @item.render is 'function'
              @item.render()

      # This is form (2).
      return @_compose name, compose: second

    # If the third parameter exists and is a function this is (3).
    if typeof third is 'function'
      return @_compose name, compose: third, options: second

    # This must be form (4).
    return @_compose name, second

  _compose: (name, options) ->
    # Assert for programmer errors
    if typeof options.compose isnt 'function' and not options.composition?
      throw new Error 'Composer#compose was used incorrectly'

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
      returned = composition.compose composition.options
      isPromise = typeof returned?.then is 'function'
      composition.stale false
      @compositions[name] = composition

    # Return the active composition
    if isPromise
      returned
    else
      @compositions[name].item

  # Retrieves an active composition using the compose method.
  retrieve: (name) ->
    active = @compositions[name]
    if active and not active.stale() then active.item

  # Declare all compositions as stale and remove all that were previously
  # marked stale without being re-composed.
  cleanup: ->
    # Action method is done; perform post-action clean up
    # Dispose and delete all no-longer-active compositions.
    # Declare all active compositions as de-activated (eg. to be removed
    # on the next controller startup unless they are re-composed).
    for key in Object.keys @compositions
      composition = @compositions[key]
      if composition.stale()
        composition.dispose()
        delete @compositions[key]
      else
        composition.stale composition.check composition.options

    # Return nothing.
    return

  disposed: false

  dispose: ->
    return if @disposed

    # Unbind handlers of global events
    @unsubscribeAllEvents()

    mediator.removeHandlers this

    # Dispose of all compositions and their items (that can be)
    for key in Object.keys @compositions
      @compositions[key].dispose()

    # Remove properties
    delete @compositions

    # Finished
    @disposed = true

    # You’re frozen when your heart’s not open
    Object.freeze this
