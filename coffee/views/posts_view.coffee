define [
  'mediator',
  'chaplin/views/collection_view', 'views/post_view',
  'text!templates/posts.hbs'
], (mediator, CollectionView, PostView, template) ->
  'use strict'

  class PostsView extends CollectionView

    # This is a workaround.
    # In the end you might want to used precompiled templates.
    template: template

    tagName: 'div' # This is not directly a list but contains a list
    id: 'posts'

    containerSelector: '#content-container'
    listSelector: 'ol' # Append the item views to this element
    fallbackSelector: '.fallback'

    initialize: ->
      super # Will render the list itself and all items
      @subscribeEvent 'loginStatus', @showHideLoginNote

    # The most important method a class derived from CollectionView
    # must overwrite.
    getView: (item) ->
      # Instantiate an item view
      new PostView model: item

    # Show/hide a login appeal if not logged in
    showHideLoginNote: ->
      @$('.login-note').css 'display', if mediator.user then 'none' else 'block'

    render: ->
      super
      @showHideLoginNote()
