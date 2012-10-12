define [
  'underscore'
  'backbone'
  'chaplin/lib/utils'
  'chaplin/lib/event_broker'
], (_, Backbone, utils, EventBroker) ->
  'use strict'

  # class Region
  #   constructor: (@selector, @cid, @options) ->
  #     # ..


  class Composer

    # Borrow the static extend method from Backbone
    @extend = Backbone.Model.extend

    # Mixin an EventBroker
    _(@prototype).extend EventBroker

    _regions: null

    constructor: ->
      @initialize arguments...

    initialize: (options = {}) ->
      @_regions = {}
      @subscribeEvent '!region:register', @registerRegion
      @subscribeEvent '!region:apply', @applyRegion
      # @subscribeEvent '!composition:activate'

    registerRegion: (selector, options, context) ->
      @_regions.push {selector, cid: context.cid, name: options.name}

    applyRegion: (name, view) ->
      # TODO: Use underscore
      for region in @_regions
        if region.name is name
          view.container = region.selector
          break

      # Don't return the for loop
      undefined
