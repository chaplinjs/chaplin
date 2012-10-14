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
      @subscribeEvent '!region:register', @registerRegion
      @subscribeEvent '!region:apply', @applyRegion
      @subscribeEvent '!composer:compose', @compose

    compose: (composition, options) ->
      # Check to see if composition is active
      check = _.find @compositions, (c) ->
        c.type is composition and
        _.isEqual c.options, options

      # Initialize and render if it isn't
      if _.isUndefined check
        @compositions.push
          type: composition
          options: _.clone options
          instance: new composition options

      # Do nothing if it is
      undefined

    registerRegion: (selector, options, context) ->
      @regions.push {selector, cid: context.cid, name: options.name}

    applyRegion: (name, view) ->
      # Find an appropriate region
      region = _.find @regions, (region) -> region.name is name

      # Apply the region selector
      view.container = region.selector

      # Don't return the for loop
      undefined
