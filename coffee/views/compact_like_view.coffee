define [
  'views/view',
  'text!templates/compact_like.hbs'
], (View, template) ->
  'use strict'

  class CompactLikeView extends View
    
    # Save the template string in a prototype property.
    # This is overwritten with the compiled template function.
    # In the end you might want to used precompiled templates.
    template: template
    template = null

    tagName: 'li'
    className: 'like'
