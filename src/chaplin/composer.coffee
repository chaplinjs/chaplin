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
    mediator.setHandler 'composer:receive', @receive, this
    @subscribeEvent 'dispatcher:dispatch', @cleanup

  # Public handler methods
  # ----------------------

  # Gets, checks and (re)creates a composition.
  # Shares the composition with the next controller.
  # Returns the object of the composition if present, otherwise the composition.
  reuse: (name, second, third) ->
    composition = @getOrCreateComposition name, second, third
    composition.object ? composition

  # Shares an object with the next controller.
  # If only a name is given, marks an existing composition as non-stale.
  # If an object is given, (re)creates a composition containing the object.
  # Returns nothing.
  share: (name, object) ->
    composition = @compositions[name]
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

  # Returns a composition that has been shared by a previous controller.
  # Does share the composition with the next controller.
  # If options are given, check if the composition can be reused.
  # Returns the object of the composition if present, otherwise the composition.
  # Returns undefined if no composition with the given name was found.
  receive: (name, options) ->
    composition = @compositions[name]
    return unless composition
    return if options? and not composition.check(options)
    composition.object ? composition

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
  getOrCreateComposition: (name, second, third) ->
    if typeof second is 'function'
      options = third
    else
      options = second.options

    composition = @compositions[name]
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
      composition = @createComposition name, second, third
    composition

  # Creates a composition.
  # This function has several forms as described below:
  #
  # 1. Second param is a class (constructor function)
  #    createComposition('name', Class[, options])
  #    Example:
  #    createComposition('image', Image, id: 123)
  #
  # 2. Second parameter is an object
  #    createComposition('name', {
  #      create: Function
  #      [check: Function]
  #      [options: Object]
  #    })
  #    Examples:
  #    createComposition('image',
  #      create: (options) ->
  #        @image = new Image options
  #    )
  #    createComposition('image',
  #      create: (options) ->
  #        @image = new Image options
  #      check: (options) ->
  #        # Created in the last ten minutes
  #        (options.time - @options.time) <= 10000
  #       options:
  #         time: new Date().getTime()
  #    )
  #
  # 3. Second parameter is a class that inherits from Composition
  #    createComposition('name', CompositionClass[, options])
  #    Example:
  #    createComposition('image', ImageComposition, { ids: [1, 2, 3] })
  #
  createComposition: (name, second, options) ->
    constructor = Composition
    if typeof second is 'function'
      if second.prototype instanceof Composition
        # Form 3
        constructor = second
      else
        # Form 1
        create = @makeCreateObject second
    else if typeof second is 'object' and typeof second.create is 'function'
      # Form 2
      create = second.create
      check = second.check
      options = second.options
    else
      throw new Error 'Composer#createComposition: Insufficient arguments'

    @_createComposition name, constructor, options, create, check

  _createComposition: (name, constructor, options, create, check) ->
    # Dispose existing composition
    composition = @compositions[name]
    composition.dispose() if composition

    # Create new composition
    composition = new constructor options
    composition.check = check if check
    composition.create = create if create
    composition.create options

    # Save composition
    @compositions[name] = composition

    composition

  makeCreateObject: (constructor) ->
    # Creates the composition object with the given options.
    # This function is called in the context of the composition.
    (options) ->
      object = new constructor options
      @object = object

      # If the object is a view and autoRender is disabled, render it.
      if typeof object.render is 'function' and not object.autoRender
        object.render()

      object

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
