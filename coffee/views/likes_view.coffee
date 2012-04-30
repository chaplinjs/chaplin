define [
  'mediator',
  'views/application_collection_view',
  'views/compact_like_view',
  'text!templates/likes.hbs'
], (mediator, ApplicationCollectionView, CompactLikeView, template) ->
  'use strict'

  class LikesView extends ApplicationCollectionView

    # Save the template string in a prototype property.
    # This is overwritten with the compiled template function.
    # In the end you might want to used precompiled templates.
    template: template
    template = null

    tagName: 'div' # This is not directly a list but contains a list
    id: 'likes'

    containerSelector: '#content-container'

    # Append the item views to this element
    listSelector: 'ol'
    # Fallback content selector
    fallbackSelector: '.fallback'
    # Loading indicator selector
    loadingSelector: '.loading'

    initialize: ->
      super # Will render the list itself and all items
      @subscribeEvent 'loginStatus', @showHideLoginNote

    # The most important method a class derived from CollectionView
    # must overwrite.
    getView: (item) ->
      # Instantiate an item view
      new CompactLikeView model: item

    # Show/hide a login appeal if not logged in
    showHideLoginNote: ->
      @$('.login-note').css 'display', if mediator.user then 'none' else 'block'

    render: ->
      super
      @showHideLoginNote()
