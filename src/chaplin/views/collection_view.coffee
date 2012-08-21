define [
  'jquery',
  'underscore',
  'chaplin/views/view'
], ($, _, View) ->
  'use strict'

  # General class for rendering Collections. Derive this class and
  # overwrite at least getView. getView gets an item model
  # and should instantiate a corresponding item view.
  class CollectionView extends View

    # Configuration options
    # ---------------------

    # These options may be overwritten in derived classes.

    # When new items are added, their views are faded in.
    # Animation duration in milliseconds (set to 0 to disable fade in)
    animationDuration: 500

    # By default, fading in is done by javascript function which can be
    # slow on mobile devices. CSS animations are faster,
    # but require user’s manual definitions.
    # CSS classes used are: animated-item-view, animated-item-view-end.
    useCssAnimation: false

    # A collection view may have a template and use one of its child elements
    # as the container of the item views. If you specify `listSelector`, the
    # item views will be appended to this element. If empty, $el is used.
    listSelector: null

    # The actual element which is fetched using `listSelector`
    $list: null

    # Selector for a fallback element which is shown if the collection is empty.
    fallbackSelector: null

    # The actual element which is fetched using `fallbackSelector`
    $fallback: null

    # Selector for a loading indicator element which is shown
    # while the collection is syncing.
    loadingSelector: null

    # The actual element which is fetched using `loadingSelector`
    $loading: null

    # Selector which identifies child elements belonging to collection
    # If empty, all children of $list are considered
    itemSelector: null

    # A class of item in collection.
    # This property has to be overridden by a derived class.
    itemView: null

    # Filtering
    # ---------

    # The filter function, if any
    filterer: null

    # View lists
    # ----------

    # Hash which saves all item views by model CID
    viewsByCid: null

    # Track a list of the visible views
    visibleItems: null

    # Returns an instance of the view class
    # This is not simply a property with a constructor so that
    # several item view constructors are possible depending
    # on the item model type.
    getView: (model) ->
      if @itemView?
        new @itemView({model})
      else
        throw new Error 'The CollectionView#itemView property must be
defined (or the getView() must be overridden)'

    # In contrast to normal views, a template is not mandatory
    # for CollectionViews. Provide an empty `getTemplateFunction`
    # which does not throw an exception if it is not overwritten.
    getTemplateFunction: ->

    initialize: (options = {}) ->
      super
      # Default options
      # These are stored as normal properties, not in Backbone’s options hash
      # so derived classes may override them when calling super.
      _(options).defaults
        render: true      # Render the view immediately per default
        renderItems: true # Render all items immediately per default
        filterer: null    # No filter function

      @itemView = options.itemView if options.itemView?

      # Initialize lists for views and visible items
      @viewsByCid = {}
      @visibleItems = []

      # Debugging
      # @bind 'visibilityChange', (visibleItems) ->
      #   console.debug 'visibilityChange', visibleItems.length
      # @modelBind 'syncStateChange', (collection, syncState) ->
      #   console.debug 'syncStateChange', syncState

      # Start observing the collection
      @addCollectionListeners()

      # Apply the filter function
      @filter options.filterer if options.filterer

      # Render template once
      @render() if options.render

      # Render all items initially
      @renderAllItems() if options.renderItems

    # Binding of collection listeners
    addCollectionListeners: ->
      @modelBind 'add',    @itemAdded
      @modelBind 'remove', @itemRemoved
      @modelBind 'reset',  @itemsResetted

    # Adding / Removing
    # -----------------

    # When an item is added, create a new view and insert it
    itemAdded: (item, collection, options = {}) =>
      @renderAndInsertItem item, options.index

    # When an item is removed, remove the corresponding view from DOM and caches
    itemRemoved: (item) =>
      @removeViewForItem item

    # When all items are resetted, render all anew
    itemsResetted: =>
      @renderAllItems()

    # Main render method (should be called only once)
    render: ->
      super

      # Set the $list property with the actual list container
      @$list = if @listSelector then @$(@listSelector) else @$el

      @initFallback()
      @initLoadingIndicator()

    # Fallback message when the collection is empty
    # ---------------------------------------------

    initFallback: ->
      return unless @fallbackSelector

      # Set the $fallback property
      @$fallback = @$(@fallbackSelector)

      # Listen for visible items changes
      @bind 'visibilityChange', @showHideFallback

      # Listen for sync events on the collection
      @modelBind 'syncStateChange', @showHideFallback

    # Show fallback if no item is visible and the collection is synced
    showHideFallback: =>
      visible = @visibleItems.length is 0 and (
        if typeof @collection.isSynced is 'function'
          # Collection is a SyncMachine
          @collection.isSynced()
        else
          # Assume it is synced
          true
      )
      @$fallback.css 'display', if visible then 'block' else 'none'

    # Loading indicator
    # -----------------

    initLoadingIndicator: ->
      # The loading indicator only works for Collections
      # which are SyncMachines.
      return unless @loadingSelector and
        typeof @collection.isSyncing is 'function'

      # Set the $loading property
      @$loading = @$(@loadingSelector)

      # Listen for sync events on the collection
      @modelBind 'syncStateChange', @showHideLoadingIndicator

      # Set visibility initially
      @showHideLoadingIndicator()

    showHideLoadingIndicator: ->
      # Only show the loading indicator if the collection is empty.
      # Otherwise loading more items in order to append them would
      # show the loading indicator. If you want the indicator to
      # show up in this case, you need to overwrite this method to
      # disable the check.
      visible = @collection.length is 0 and @collection.isSyncing()
      @$loading.css 'display', if visible then 'block' else 'none'

    # Filtering
    # ---------

    # Applies a filter to the collection view.
    # Expects an iterator function as parameter.
    # If no callback, hides all items for which the iterator returns false.
    filter: (filterer, callback) ->
      # Save the new filterer function
      @filterer = filterer
      hasCallback = callback if typeof callback is 'function'

      # Show/hide existing views
      unless _(@viewsByCid).isEmpty()
        for item, index in @collection.models

          # Apply filter to the item
          included = if typeof filterer is 'function'
            filterer item, index
          else
            true

          # Show/hide the view accordingly
          view = @viewsByCid[item.cid]
          # A view has not been created for this item yet
          unless view
            throw new Error 'CollectionView#filter: ' +
              "no view found for #{item.cid}"

          # apply a callback, or hide if none
          if hasCallback
            callback view, included
          else
            view.$el
              .stop(true, true)
              .css('display', if included then '' else 'none')

            # Update visibleItems list, but do not trigger
            # a `visibilityChange` event immediately
            @updateVisibleItems item, included, false

      # Trigger a combined `visibilityChange` event
      @trigger 'visibilityChange', @visibleItems

    # Item view rendering
    # -------------------

    # Render and insert all items
    renderAllItems: =>
      items = @collection.models

      # Reset visible items
      @visibleItems = []

      # Collect remaining views
      remainingViewsByCid = {}
      for item in items
        view = @viewsByCid[item.cid]
        if view
          # View remains
          remainingViewsByCid[item.cid] = view

      # Remove old views of items not longer in the list
      for own cid, view of @viewsByCid
        # Check if the view remains
        unless cid of remainingViewsByCid
          # Remove the view
          @removeView cid, view

      # Re-insert remaining items; render and insert new items
      for item, index in items
        # Check if view was already created
        view = @viewsByCid[item.cid]
        if view
          # Re-insert the view
          @insertView item, view, index, false
        else
          # Create a new view, render and insert it
          @renderAndInsertItem item, index

      # If no view was created, trigger `visibilityChange` event manually
      unless items.length
        @trigger 'visibilityChange', @visibleItems

    # Render the view for an item
    renderAndInsertItem: (item, index) ->
      view = @renderItem item
      @insertView item, view, index

    # Instantiate and render an item using the `viewsByCid` hash as a cache
    renderItem: (item) ->
      # Get the existing view
      view = @viewsByCid[item.cid]

      # Instantiate a new view by calling getView if necessary
      unless view
        view = @getView(item)
        # Save the view in the viewsByCid hash
        @viewsByCid[item.cid] = view

      # Render in any case
      view.render()

      view

    # Inserts a view into the list at the proper position
    insertView: (item, view, index = null, enableAnimation = true) ->
      # Get the insertion offset
      position = if typeof index is 'number'
        index
      else
        @collection.indexOf item

      # Is the item included in the filter?
      included = if typeof @filterer is 'function'
        @filterer item, position
      else
        true

      # Get the view’s top element
      viewEl = view.el
      $viewEl = view.$el

      if included
        # Make view transparent if animation is enabled
        if enableAnimation
          if @useCssAnimation
            $viewEl.addClass 'animated-item-view'
          else
            $viewEl.css 'opacity', 0
      else
        # Hide the view if it’s filtered
        $viewEl.css 'display', 'none'

      # Insert the view into the list
      $list = @$list

      # Get the children which originate from item views
      children = if @itemSelector
        $list.children @itemSelector
      else
        $list.children()

      # Check if it needs to be inserted
      unless children.get(position) is viewEl
        length = children.length
        if length is 0 or position is length
          # Insert at the end
          $list.append viewEl
        else
          # Insert at the right position
          if position is 0
            $next = children.eq position
            $next.before viewEl
          else
            $previous = children.eq position - 1
            $previous.after viewEl

      # Tell the view that it was added to the DOM
      view.trigger 'addedToDOM'

      # Update the list of visible items, trigger a `visibilityChange` event
      @updateVisibleItems item, included

      # Fade the view in if it was made transparent before
      if enableAnimation and included
        if @useCssAnimation
          # Wait for DOM state change.
          setTimeout =>
            $viewEl.addClass 'animated-item-view-end'
          , 0
        else
          $viewEl.animate {opacity: 1}, @animationDuration

      return

    # Remove the view for an item
    removeViewForItem: (item) ->
      # Remove item from visibleItems list, trigger a `visibilityChange` event
      @updateVisibleItems item, false

      # Get the view
      view = @viewsByCid[item.cid]

      @removeView item.cid, view

    # Remove a view
    removeView: (cid, view) ->
      # Dispose the view
      view.dispose()

      # Remove the view from the hash
      delete @viewsByCid[cid]

    # List of visible items
    # ---------------------

    # Update visibleItems list and trigger a `visibilityChanged` event
    # if an item changed its visibility
    updateVisibleItems: (item, includedInFilter, triggerEvent = true) ->
      visibilityChanged = false

      visibleItemsIndex = _(@visibleItems).indexOf item
      includedInVisibleItems = visibleItemsIndex > -1

      if includedInFilter and not includedInVisibleItems
        # Add item to the visible items list
        @visibleItems.push item
        visibilityChanged = true

      else if not includedInFilter and includedInVisibleItems
        # Remove item from the visible items list
        @visibleItems.splice visibleItemsIndex, 1
        visibilityChanged = true

      # Trigger a `visibilityChange` event if the visible items changed
      if visibilityChanged and triggerEvent
        @trigger 'visibilityChange', @visibleItems

      visibilityChanged

    # Disposal
    # --------

    dispose: ->
      return if @disposed

      # Dispose all item views
      view.dispose() for own cid, view of @viewsByCid

      # Remove jQuery objects, item view cache and visible items list
      properties = [
        '$list', '$fallback', '$loading',
        'viewsByCid', 'visibleItems'
      ]
      delete this[prop] for prop in properties

      # Self-disposal
      super
