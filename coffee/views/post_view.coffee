define ['views/view', 'text!templates/post.hbs'], (View, template) ->
  'use strict'

  class PostView extends View
    # This is a workaround.
    # In the end you might want to used precompiled templates.
    template: template

    tagName: 'li'
    className: 'post'
