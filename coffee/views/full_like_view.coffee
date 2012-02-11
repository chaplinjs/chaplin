define ['mediator', 'views/view', 'text!templates/full_like.hbs'], (mediator, View, template) ->

  'use strict'

  class FullLikeView extends View

    # This is a workaround. In the end you might want to used precompiled templates.
    @template = template

    id: 'like'
    containerSelector: '#content-container'

    initialize: ->
      super
      console.debug 'FullLikeView#initialize'

      # Render initially
      @render()
      # Render again when the model is resolved
      @model.done @render

    # Rendering

    render: ->
      super
      console.debug 'FullLikeView#render'

      # Append to DOM
      @$container.append @el

      # Parse Facebook widgets
      user = mediator.user
      provider = user.get 'provider'
      if provider.name is 'facebook'
        provider.parse @el
