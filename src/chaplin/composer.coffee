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
  # To compose a view:
  #   @publishEvent '!composer:compose', View, options
  #
  # If the view has already been composed by a previous action then nothing
  # apart from registering the view as in use happens. Else, the view
  # is instantiated and passed the options that were passed in. If an action
  # is routed to where a view that was composed is not re-composed, the
  # composed view is disposed.
  #
  # Views that are composed are additionaly allowed to register regions.
  # Regions are named containers and are registered as follows (from the
  # view class that is being composed):
  #   regions: (region) ->
  #     region 'name', selector: '#id'
  #     region 'name', selector: '.class#id'
  #
  # All views are allowed to be placed inside a region (composed ones included)
  #  new View region: 'name'

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

    compose: (type, options = {}) ->
      # Check to see if composition is active
      check = _.find @compositions, (c) ->
        c.type is type and
        _.isEqual c.options, options

      # Initialize and render if it isn't
      if _.isUndefined check
        # Build composition
        composition =
          type: type
          options: _.clone options

        # Instantiate the composition
        composition.instance = new type options

        # Render the composition
        composition.instance.render() unless composition.instance.autoRender

        # Append to the list so we can dispose and track the
        # composition
        @compositions.push composition

      else
        # Declare composition as not stale so that its regions will now be
        # counted
        check.instance.stale = false

    onStartupController: (options) ->
      # Action method is done; perform post-action clean up
      # Dispose and delete all unactive compositions
      # Declare all active compositions as de-activated
      @compositions = for composition, index in @compositions
        unless composition.instance.stale
          composition.instance.stale = true
          composition
        else
          composition.instance.dispose()
          continue

    dispose: ->
      return if @disposed

      # Dispose of all compositions
      composition.instance.dispose() for composition in @compositions

      # Destroy collections
      @compositions = @compositions[..]

      # Remove properties
      delete @compositions

      # Finished
      @disposed = true

      # You’re frozen when your heart’s not open
      Object.freeze? this
