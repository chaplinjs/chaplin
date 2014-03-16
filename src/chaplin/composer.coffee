'use strict'

_ = require 'underscore'
Backbone = require 'backbone'
mediator = require 'chaplin/mediator'
utils = require 'chaplin/lib/utils'
Composition = require 'chaplin/lib/composition'
EventBroker = require 'chaplin/lib/event_broker'

# Composer
# --------

# The job of the Composer is to save objects (typically models, collections or
# views) so they might be reused by other controllers. The objects are wapped
# in a Composition instance that has a create and check method.
#
# The composer is the primary memory management mechanism in Chaplin
# applications. Typically, all objects created in a controller are disposed
# when another controller is created. The Composer allows to share objects
# between controllers so they do not have to be re-created.
#
# If an object has already been created by a previous controller action,
# the object is just marked as “in use”. If the object does not exist, an
# instance is created using the constructor and the options that were passed
# in. If an action is called that does not reuse a saved object, the object is
# composed view is disposed.

class Composer
  # Borrow the static extend method from Backbone
  @extend = Backbone.Model.extend

  # Mixin an EventBroker
  _.extend @prototype, EventBroker

  # The collection of compositions
  compositions: null

  constructor: ->
    @initialize arguments...

  initialize: (options = {}) ->
    # Initialize collections.
    @compositions = {}

    # Subscribe to events.
    mediator.setHandler 'composer:reuse', @reuse, this
    mediator.setHandler 'composer:share', @share, this
    mediator.setHandler 'composer:retrieve', @retrieve, this
    @subscribeEvent 'dispatcher:dispatch', @cleanup

  # Public handler methods
  # ----------------------

  # Retrieves, checks and (re)creates a composition.
  # Shares the composition with the next controller.
  reuse: (name, func, options) ->
    composition = @getOrCreateComposition name, func, options
    composition.object

  # Shares an object with the next controller.
  # If only a name is given, marks an existing composition as non-stale.
  # If an object is given, (re)creates a composition containing the object.
  share: (name, object) ->
    composition = @getComposition name
    if object?
      # (Re)create the composition.
      composition.dispose() if composition
      composition = new Composition()
      # Don’t call `create`, just assign the object.
      composition.object = object
      @compositions[name] = composition
    else
      # Mark composition as non-stale.
      unless composition
        throw new Error "Composer#share: Composition #{name} not found"
      composition.stale false
    return

  # Retrieves non-stale composition. If options are given, check if the
  # composition can be reused.
  retrieve: (name, options) ->
    composition = @getComposition name
    if object? and not composition.check(options)
      return undefined
    composition.object

  # Disposes all stale compositions, marks non-stale as stale.
  cleanup: ->
    # This method is called after the controller action.
    # Dispose and delete all stale compositions.
    # Mark all active compositions as stale (eg. to be removed
    # on the next controller startup unless they are re-composed).
    for name, composition of @compositions
      if composition.stale()
        composition.dispose()
        delete @compositions[name]
      else
        composition.stale true
    return

  # Internal helpers
  # ----------------

  # Checks if a composition exists and can be reused,
  # otherwise create a new one.
  getOrCreateComposition: (name, func, options) ->
    composition = @getComposition()
    if composition
      # Check if the composition can be reused.
      if composition.check(options)
        # Mark existing composition as non-stale.
        composition.stale false
      else
        # Check failed, dispose existing.
        composition.dispose()
        composition = null
    unless composition
      # Create from scratch.
      composition = @createComposition name, func, options
    composition

  # Returns a non-stale composition.
  getComposition: (name) ->
    composition = @compositions[name]
    return undefined unless composition or composition.stale()
    composition

  # Creates a composition.
  # This function has several forms as described below:
  #
  # 1. Second param is a class (constructor function)
  #    createComposition('name', Class[, options])
  #    Example:
  #    createComposition('image', Image, id: 123)
  #
  # 2. Second parameter is an object with `create` and `check` functions
  #    createComposition('name', { create: Function, check: Function })
  #    Example:
  #    createComposition('image',
  #      create: ->
  #        now = new Date().getTime()
  #        @image = new Image created: now
  #      check: ->
  #        now = new Date().getTime()
  #        // Created in the last ten minutes
  #        (now - @image.get('created')) <= 10000
  #    )
  #
  # 3. Second parameter is a class that inherits from Composition
  #    createComposition('name', CompositionClass[, options])
  #    Example:
  #    createComposition('image', ImageComposition, { ids: [1, 2, 3] })
  #
  createComposition: (name, second, options) ->
    if typeof second is 'function'
      func = second
    else if typeof second is 'object'
      create = second.create
      check = second.check
      # Use the as options, they can be used
      options = { create, check }

    # Dispose existing composition
    composition = @compositions[name]
    composition.dispose() if composition

    constructor = if func.prototype instanceof Composition
      func
    else
      Composition

    composition = new constructor options
    composition.check = check if check
    composition.create = create if create
    composition.create()

    @compositions[name] = composition

    composition

  # Disposal
  # --------

  disposed: false

  dispose: ->
    return if @disposed

    # Unbind handlers of global events
    @unsubscribeAllEvents()

    mediator.removeHandlers this

    # Dispose of all compositions
    composition.dispose() for name, composition of @compositions

    # Remove properties
    delete @compositions

    # Finished
    @disposed = true

    # You’re frozen when your heart’s not open
    Object.freeze? this

module.exports = Composer
