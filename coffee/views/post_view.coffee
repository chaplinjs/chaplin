define [
  'views/application_view',
  'text!templates/post.hbs'
], (ApplicationView, template) ->
  'use strict'

  class PostView extends ApplicationView

    # Save the template string in a prototype property.
    # This is overwritten with the compiled template function.
    # In the end you might want to used precompiled templates.
    template: template
    template = null

    tagName: 'li'
    className: 'post'
