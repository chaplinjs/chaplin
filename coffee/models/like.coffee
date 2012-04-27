define [
  'underscore',
  'mediator',
  'chaplin/models/model'
], (_, mediator, Model) ->
  'use strict'

  class Like extends Model
    initialize: (attributes, options) ->
      super
      ###console.debug 'Like#initialize', attributes, options###

      if options and options.loadDetails

        # Mixin a Deferred
        _(this).extend $.Deferred()

        @fetch()

    # Custom fetch function since the Facebook graph is not
    # a REST/JSON API which might be accessed using Ajax
    fetch: ->
      ###console.debug 'Like#getLike'###

      user = mediator.user
      return unless user

      provider = user.get 'provider'
      return unless provider.name is 'facebook'
      provider.getInfo @id, @processLike

    processLike: (response) =>
      ###console.debug 'Like#processLike', response###
      @set response
      @resolve()

