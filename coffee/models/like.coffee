define ['mediator', 'models/model'], (mediator, Model) ->
  'use strict'

  class Like extends Model
    initialize: (attributes, options) ->
      super

      if options and options.loadDetails

        # Mixin a Deferred
        _(this).extend $.Deferred()

        @getLike()

    getLike: ->
      user = mediator.user
      return unless user

      provider = user.get 'provider'
      return unless provider.name is 'facebook'

      @trigger 'loadStart'
      provider.getInfo @id, @processLike

    processLike: (response) =>
      @trigger 'load'
      @set response
      @resolve()

