define [
  'mediator', 'views/collection_view', 'views/compact_like_view',
  'text!templates/likes.hbs'
], (mediator, CollectionView, CompactLikeView, template) ->
  'use strict'

  class LikesView extends CollectionView
    # This is a workaround.
    # In the end you might want to used precompiled templates.
    @template: template

    tagName: 'div' # This is not directly a list but contains a list
    id: 'likes'

    containerSelector: '#content-container'
    listSelector: 'ol' # Append the item views to this element
    fallbackSelector: '.fallback'

    initialize: ->
      super # Will render the list itself and all items
      @subscribeEvent 'loginStatus', @showHideLoginNote

    # The most important method a class inheriting from CollectionView
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
