define ['views/collection_view', 'views/compact_like_view', 'text!templates/likes.hbs'], (CollectionView, CompactLikeView, template) ->

  'use strict'

  class LikesView extends CollectionView

    # This is a workaround. In the end you might want to used precompiled templates.
    @template: template

    tagName: 'div' # This is not directly a list
    id: 'likes'

    containerSelector: '#content-container'

    initialize: ->
      super # Will render the list itself and all items

      @subscribeEvent 'loginStatus', @loginStatus
      @bind 'visibilityChange', @visibilityChangeHandler

    # The most important method a class inheriting from CollectionView
    # has to overwrite.
    getView: (item) ->
      # Instantiate an item view
      new CompactLikeView model: item

    loginStatus: (loginStatus) ->
      @$('.login-note').css 'display', if loginStatus then 'none' else 'block'

    visibilityChangeHandler: (visibleItems) ->
      # Show fallback message if no item is visible
      empty = visibleItems.length is 0 and @collection.state() is 'resolved'
      @$fallback.css 'display', if empty then 'block' else 'none'

    # Rendering
    # Main render method (called once)

    render: ->
      super
      #console.debug 'StreamView#render', @

      # Append to DOM
      @$container.append @el

      # Don't append item views to the root, but to a nested element
      @$listElement = $('#likes-list')

      # Fallback if the list is empty
      @$fallback = @$('.fallback')
