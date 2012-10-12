define [
  'jquery'
  'underscore'
  'backbone'
  'chaplin/lib/utils'
  'chaplin/lib/event_broker'
  'chaplin/models/model'
  'chaplin/views/view'
], ($, _, Backbone, utils, EventBroker, Model, View) ->
  'use strict'

  class Composition extends View
    # ..

    # ..
    regions: undefined

    initialize: ->
      super

      # register all regions with the composer
      @regions @registerRegion if @regions?

    registerRegion: (selector, options) =>
      @publishEvent '!region:register', selector, options, @
