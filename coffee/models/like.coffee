define [
  'underscore',
  'mediator',
  'chaplin/models/model'
], (_, mediator, Model) ->
  'use strict'

  class Like extends Model
    initialize: (attributes, options) ->
      super
      #console.debug 'Like#initialize', attributes, options

      if options and options.loadDetails

        # Mixin a Deferred
        _(this).extend $.Deferred()

        @getLike()

    getLike: ->
      #console.debug 'Like#getLike'

      user = mediator.user
      return unless user

      provider = user.get 'provider'
      return unless provider.name is 'facebook'

      @trigger 'loadStart'
      #console.debug 'getInfo', @id, @processLike
      provider.getInfo @id, @processLike

    processLike: (response) =>
      #console.debug 'Like#processLike', response

      @trigger 'load'
      @set response
      @resolve()

