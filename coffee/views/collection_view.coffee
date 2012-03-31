define ['lib/utils', 'views/view'], (utils, View) ->
  'use strict'

  # General class for rendering Collections. Inherit from this class and
  # overwrite at least getView. getView gets an item model
  # and should instantiate a corresponding item view.
  class CollectionView extends View

    # Animation duration when adding new items (set to 0 to disable fade in)
    animationDuration: 500

    # Hash which saves all item views by CID
    viewsByCid: null

    # The list element the item views are actually appended to.
    # If empty, $el is used.
    # Set the selector property in the derived class to use a specific element.
    listSelector: null
    $list: null

    # Selector for a fallback element which is shown if the collection is empty.
    # Set the selector property in the derived class to use a specific element.
    fallbackSelector: null
    $fallback: null

    # Selector which identifies child elements belonging to collection
    # All children are seen as belonging to collection if not present
    itemSelector: null

    # Track a list of the visible views
    visibleItems: null

    # Returns an instance of the view class
    # This method has to be overridden by a derived class.
    # This is not simply a property with a constructor so that
    # several item view constructors are possible depending
    # on the item model type.
    getView: ->
      throw new Error 'CollectionView#getView must be overridden'

    initialize: (options = {}) ->
      super
      #console.debug 'CollectionView#initialize', this, @collection, options

      # Default options
      _(options).defaults
        render: true      # Render the view immediately per default
        renderItems: true # Render all items immediately per default
        filterer: null    # No filter function

      # Initialize lists for views and visible items
      @viewsByCid = {}
      @visibleItems = []

      # Start observing the model
      @addCollectionListeners()

      # Set the filter function
      @filter options.filterer if options.filterer

      # Render template once
      @render() if options.render

      # Render all items initially
      @renderAllItems() if options.renderItems

    # Binding of collection listeners
    addCollectionListeners: ->
      @modelBind 'loadStart', @showLoadingIndicator
      @modelBind 'load',      @hideLoadingIndicator
      @modelBind 'add',       @itemAdded
      @modelBind 'remove',    @itemRemoved
      @modelBind 'reset',     @itemsResetted

    # Generic loading indicator
    showLoadingIndicator: =>
      # Only show the loading indicator if the collection is empty
      # (otherwise the pagination should show a loading indicator)
      return if @collection.length
      @$('.loading').css 'display', 'block'

    hideLoadingIndicator: =>
      @$('.loading').css 'display', 'none'

    # Adding / Removing
    # -----------------

    # When an item is added, create a new view and insert it
    itemAdded: (item, collection, options = {}) =>
      #console.debug 'CollectionView#itemAdded', this, item.cid, item
      @renderAndInsertItem item, options.index

    # When an item is removed, remove the corresponding view from DOM and caches
    itemRemoved: (item) =>
      #console.debug 'CollectionView#itemRemoved', this, item.cid, item
      @removeViewForItem item

    # When all items are resetted, render all anew
    itemsResetted: =>
      #console.debug 'CollectionView#itemsResetted', this, @collection.length, @collection.models
      @renderAllItems()

    # Main render method (should be called only once)
    render: ->
      super
      #console.debug 'CollectionView#render', this, @collection

      # Set the $list property
      @$list = if @listSelector then @$(@listSelector) else @$el

      @initFallback()

    #
    # Fallback message when the collection is empty
    #

    # Initialize the fallback
    initFallback: ->
      return unless @fallbackSelector

      #console.debug 'CollectionView#initFallback', this, @el, @el.parentNode

      # Set the $fallback property
      @$fallback = @$(@fallbackSelector)

      # The collection has to be a deferred in order that
      # the fallback can be shown properly
      f = 'function'
      isDeferred = (typeof @collection.done is f and
        typeof @collection.state is f)
      return unless isDeferred

      # Listen for visible items changes
      @bind 'visibilityChange', @showHideFallback

    # Show or hide the fallback when the visible items change
    showHideFallback: =>
      #console.debug 'CollectionView#showHideFallback', this, 'visibleItems', @visibleItems, 'collection', @collection
      # Show fallback message if no item is visible and
      # the collection Deferred has been resolved
      empty = @visibleItems.length is 0 and @collection.state() is 'resolved'
      @$fallback.css 'display', if empty then 'block' else 'none'

    # Render and insert all items
    renderAllItems: =>

      items = @collection.models
      #console.debug 'CollectionView#renderAllItems', items.length

      # Reset visible items
      @visibleItems = []

      # Collect remaining views
      remainingViewsByCid = {}
      for item in items
        view = @viewsByCid[item.cid]
        if view
          #console.debug '\tview for', item.cid, 'remains'
          remainingViewsByCid[item.cid] = view

      # Remove old views of items not longer in the list
      for own cid, view of @viewsByCid
        #console.debug '\tcheck', cid, view, 'remaining?', cid of remainingViewsByCid
        unless cid of remainingViewsByCid
          #console.debug '\t\tremove view for', cid
          @removeView cid, view

      # Re-insert remaining items; render and insert new items
      #console.debug '\tbuild up list again'
      for item, index in items
        # View already created?
        view = @viewsByCid[item.cid]
        if view
          # Re-insert the view
          #console.debug '\tre-insert', item.cid
          @insertView item, view, index, 0
        else
          # Create a new view, render and insert it
          #console.debug '\trender and insert new view for', item.cid
          @renderAndInsertItem item, index

      # If no view was created, trigger `visibilityChange` event manually
      unless items.length
        #console.debug 'CollectionView#renderAllItems', 'visibleItems', @visibleItems.length
        @trigger 'visibilityChange', @visibleItems

    # Applies a filter to the collection.
    # Expects an interator function as parameter.
    # Hides all items for which the iterator returns false.
    filter: (filterer) ->
      #console.debug 'CollectionView#filter', this, @collection

      # Save the new filterer function
      @filterer = filterer

      # Show/hide existing views
      unless _(@viewsByCid).isEmpty()
        for item, index in @collection.models

          # Apply filter to the item
          included = if filterer then filterer(item, index) else true

          # Show/hide the view accordingly
          view = @viewsByCid[item.cid]
          # A view has not been created for this item yet
          unless view
            #console.debug 'CollectionView#filter: no view for', item.cid, item
            continue

          #console.debug item, item.cid, view
          $(view.el).stop(true, true)[if included then 'show' else 'hide']()

          # Update visibleItems list, but do not trigger an event immediately
          @updateVisibleItems item, included, false

      # Trigger a combined `visibilityChange` event
      #console.debug 'CollectionView#filter', 'visibleItems', @visibleItems.length
      @trigger 'visibilityChange', @visibleItems

    # Render the view for an item
    renderAndInsertItem: (item, index) ->
      #console.debug 'CollectionView#renderAndInsertItem', item.cid, item

      view = @renderItem item
      @insertView item, view, index

    # Instantiate and render an item using the viewsByCid hash as a cache
    renderItem: (item) ->
      #console.debug 'CollectionView#renderItem', item.cid, item

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
    insertView: (item, view, index = null, animationDuration = @animationDuration) ->
      #console.debug 'CollectionView#insertView', item, view, index

      # Get the insertion offset
      position = if typeof index is 'number'
        index
      else
        @collection.indexOf(item)
      #console.debug '\titem', item.id, 'position', position, 'length', @collection.length

      # Is the item included in the filter?
      included = if @filterer then @filterer(item, position) else true
      #console.debug '\tincluded?', included

      # Get the view’s top element
      $viewEl = view.$el

      if included
        # Make view transparent if animation is enabled
        $viewEl.css 'opacity', 0 if animationDuration
      else
        # Hide the view if it’s filtered
        $viewEl.css 'display', 'none'

      # Get the lsit and its children which are originate from item views
      $list = @$list
      children = $list.children(@itemSelector)

      if position is 0
        # Insert at the beginning
        #console.debug '\tinsert at the beginning'
        $list.prepend($viewEl)
      else if position < children.length
        # Insert at the right position
        #console.debug '\tinsert before', children.eq(position)
        children.eq(position).before($viewEl)
      else
        # Insert at the end
        #console.debug '\tinsert at the end'
        $list.append($viewEl)

      # Tell the view that it was added to the DOM
      view.trigger 'addedToDOM'

      # Update the list of visible items, fire a `visibilityChange` event
      @updateVisibleItems item, included

      # Fade the view in if it was made transparent before
      if animationDuration and included
        $viewEl.animate {opacity: 1}, animationDuration

    # Remove the view for an item
    removeViewForItem: (item) ->
      #console.debug 'CollectionView#removeViewForItem', this, item

      # Remove item from visibleItems list
      @updateVisibleItems item, false

      # Get the view
      view = @viewsByCid[item.cid]

      @removeView item.cid, view

    # Remove a view
    removeView: (cid, view) ->
      #console.debug 'CollectionView#removeView', cid, view

      # Dispose the view
      view.dispose()

      # Remove the view from the hash table
      delete @viewsByCid[cid]

    # Update visibleItems list and trigger a `visibilityChanged` event
    # if an item changed its visibility
    updateVisibleItems: (item, includedInFilter, triggerEvent = true) ->
      visibilityChanged = false

      visibleItemsIndex = _(@visibleItems).indexOf item
      includedInVisibleItems = visibleItemsIndex > -1
      #console.debug 'CollectionView#updateVisibleItems', @collection.constructor.name, item.id, 'included?', includedInFilter

      if includedInFilter and not includedInVisibleItems
        # Add item to the visible items list
        @visibleItems.push item
        visibilityChanged = true

      else if not includedInFilter and includedInVisibleItems
        # Remove item from the visible items list
        @visibleItems.splice visibleItemsIndex, 1
        visibilityChanged = true

      #console.debug '\tvisibilityChanged?', visibilityChanged, 'visibleItems', @visibleItems.length, 'triggerEvent?', triggerEvent

      # Trigger a `visibilityChange` event if the visible items changed
      if visibilityChanged and triggerEvent
        @trigger 'visibilityChange', @visibleItems

      visibilityChanged

    # Remove the whole list from DOM
    dispose: =>
      #console.debug 'CollectionView#dispose', this, 'disposed?', @disposed
      return if @disposed

      # Dispose all item views
      view.dispose() for own cid, view of @viewsByCid

      # Remove jQuery objects, item view cache and visible items list
      properties = [
        '$list', '$fallback', 'viewsByCid', 'visibleItems'
      ]
      delete @[prop] for prop in properties

      # Self-disposal
      super
