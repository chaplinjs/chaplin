define [
  'chaplin/views/view', 'text!templates/compact_like.hbs'
], (View, template) ->
  'use strict'

  class CompactLikeView extends View
    # This is a workaround.
    # In the end you might want to used precompiled templates.
    template: template

    tagName: 'li'
    className: 'like'
