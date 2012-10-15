define [
  'underscore'
  'backbone'
  'chaplin/lib/utils'
  'chaplin/lib/event_broker'
], (_, Backbone, utils, EventBroker) ->
  'use strict'

  class Composer

    # Borrow the static extend method from Backbone
    @extend = Backbone.Model.extend

    # Mixin an EventBroker
    _(@prototype).extend EventBroker

    # The collection of registered regions
    regions: null

    # The collection of composed compositions
    compositions: null

    constructor: ->
      @initialize arguments...

    initialize: (options = {}) ->
      # initialize collections
      @regions = []
      @compositions = []

      # subscribe to events
      @subscribeEvent '!region:apply', @applyRegion
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
          active: true

        # Ensure composition is not set to autoRender as we need
        # to register the regions before it is rendered
        options.autoRender = false

        # Instantiate the composition
        composition.instance = new type options

        # Register the exposed regions
        @registerRegions composition.instance

        # Render the composition
        composition.instance.render()

        # Append to the list so we can dispose and track the
        # composition
        @compositions.push composition

      else
        # Declare composition as actively in use so that it does not
        # get diposed
        check.active = true

        # Re-register the exposed regions
        @registerRegions check.instance

    onStartupController: (options) ->
      # Action method is done; perform post-action clean up
      # Dispose and delete all unactive compositions
      # Declare all active compositions as de-activated
      @compositions = for composition, index in @compositions
        if composition.active
          composition.active = false
          composition
        else
          composition.instance.dispose()
          continue

      # Unregister all regions
      @regions = @regions[..]

    registerRegions: (instance) ->
      instance.regions _.partial @registerRegion, instance if instance.regions?

    registerRegion: (context, selector, options) =>
      @regions.push {selector, cid: context.cid, name: options.name}

    applyRegion: (name, view) ->
      # Find an appropriate region
      region = _.find @regions, (region) -> region.name is name

      # Apply the region selector
      view.container = region.selector

      # Don't return the for loop
      undefined

    dispose: ->
      return if @disposed

      # Dispose of all compositions
      composition.instance.dispose() for composition in @compositions

      # Destroy collections
      @regions = @regions[..]
      @compositions = @compositions[..]

      # Remove properties
      delete @compositions
      delete @regions

      # Finished
      @disposed = true

      # You’re frozen when your heart’s not open
      Object.freeze? this
