define [
  'underscore'
  'backbone'
  'chaplin/lib/utils'
  'chaplin/lib/event_broker'
], (_, Backbone, utils, EventBroker) ->
  'use strict'

  # Composer
  # --------

  # The sole job of the composer is to allow views to be 'composed'.
  # To compose a view (short form):
  #
  # @publishEvent '!composer:compose', ViewClass, options
  #
  # Or (long form):
  #
  # @publishEvent '!composer:compose',
  #   compose: ->
  #     composition = {}
  #     composition.model = new Model()
  #     composition.model.id = 42
  #
  #     composition.view = new View
  #       model: composition.model
  #
  #     composition.model.fetch()
  #     composition
  #
  #   check: (composition) ->
  #     composition.model.id is 42 and
  #     typeof composition.view is typeof View
  #
  # If the view has already been composed by a previous action then nothing
  # apart from registering the view as in use happens. Else, the view
  # is instantiated and passed the options that were passed in. If an action
  # is routed to where a view that was composed is not re-composed, the
  # composed view is disposed.

  class Composer

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
      @compositions = []

      # subscribe to events
      @subscribeEvent '!composer:compose', @compose
      @subscribeEvent 'startupController', @onStartupController

    perform: (type, options) ->
      # Perform the composition; this is the function
      # that is overidden when the `compose` option is passed to the
      # compose function
      type: type
      options: _(options).clone()
      view: new type options

    stale: (composition, value) ->
      # Set the stale property on the composition
      composition.stale = value

      # Sets the stale property for every item in the composition that has it
      for name, item of composition when _(item).has 'stale'
        item.stale = value

      # Don't bother to return the for loop
      undefined

    compose: (type, options = {}) ->
      # Short form (view-class, ctor-options) or long form ?
      if arguments.length is 2 or _(type).isFunction()
        # Assume short form; apply functions
        options.compose = _(@perform).partial type, options
        options.check = (composition) ->
          composition.type is type and _(composition.options).isEqual options

      # Assert for programmer errors
      unless _(options.compose).isFunction()
        throw new Error "options#compose must be defined"

      unless _(options.check).isFunction()
        throw new Error "options#check must be defined"

      # Attempt to find an active composition that matches
      composition = _(@compositions).find options.check

      if composition?
        # We have an active composition; declare composition as not stale so
        # that its regions will now be counted
        @stale composition, false

      else
        # Perform the composition and append to the list so we can
        # track its lifetime
        @compositions.push options.compose()

    destroy: (composition) ->
      # Dispose of everything that can be disposed
      for name, item of composition when _(item?.dispose).isFunction()
        item.dispose()
        delete composition[name]

      # Don't bother to return the for loop
      undefined

    onStartupController: (options) ->
      # Action method is done; perform post-action clean up
      # Dispose and delete all unactive compositions
      # Declare all active compositions as de-activated
      @compositions = for composition, index in @compositions
        if composition.stale
          @destroy composition
          continue
        else
          @stale composition, true
          composition

    dispose: ->
      return if @disposed

      # Dispose of all compositions and their items (that can be)
      @destroy composition for composition in @compositions

      # Destroy collections
      @compositions = @compositions[..]

      # Remove properties
      delete @compositions

      # Finished
      @disposed = true

      # You’re frozen when your heart’s not open
      Object.freeze? this
