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
    _regions: null

    constructor: ->
      @initialize arguments...

    initialize: (options = {}) ->
      @_regions = []
      @subscribeEvent '!region:register', @registerRegion
      @subscribeEvent '!region:apply', @applyRegion

    registerRegion: (selector, options, context) ->
      @_regions.push {selector, cid: context.cid, name: options.name}

    applyRegion: (name, view) ->
      # Find an appropriate region
      region = _.find @_regions, (region) -> region.name is name

      # Apply the region selector
      view.container = region.selector

      # Don't return the for loop
      undefined
