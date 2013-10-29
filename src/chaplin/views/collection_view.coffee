'use strict'

_ = require 'underscore'
Backbone = require 'backbone'
View = require 'chaplin/views/view'
utils = require 'chaplin/lib/utils'

# Shortcut to access the DOM manipulation library.
$ = Backbone.$

filterChildren = (nodeList, selector) ->
  return nodeList unless selector
  for node in nodeList when Backbone.utils.matchesSelector node, selector
    node

toggleElement = do ->
  if $
    (elem, visible) -> elem.toggle visible
  else
    (elem, visible) ->
      elem.style.display = (if visible then '' else 'none')

addClass = do ->
  if $
    (elem, cls) -> elem.addClass cls
  else
    (elem, cls) -> elem.classList.add cls

startAnimation = do ->
  if $
    (elem, useCssAnimation, cls) ->
      if useCssAnimation
        addClass elem, cls
      else
        elem.css 'opacity', 0
  else
    (elem, useCssAnimation, cls) ->
      if useCssAnimation
        addClass elem, cls
      else
        elem.style.opacity = 0

endAnimation = do ->
  if $
    (elem, duration) -> elem.animate {opacity: 1}, duration
  else
    (elem, duration) ->
      elem.style.transition = "opacity #{(duration / 1000)}s"
      elem.opacity = 1

insertView = do ->
  if $
    (list, viewEl, position, length, itemSelector) ->
      insertInMiddle = (0 < position < length)
      isEnd = (length) -> length is 0 or position is length

      if insertInMiddle or itemSelector
        # Get the children which originate from item views.
        children = list.children itemSelector
        childrenLength = children.length

        # Check if it needs to be inserted.
        unless children[position] is viewEl
          if isEnd childrenLength
            # Insert at the end.
            list.append viewEl
          else
            # Insert at the right position.
            if position is 0
              children.eq(position).before viewEl
            else
              children.eq(position - 1).after viewEl
      else
        method = if isEnd length then 'append' else 'prepend'
        list[method] viewEl
  else
    (list, viewEl, position, length, itemSelector) ->
      insertInMiddle = (0 < position < length)
      isEnd = (length) -> length is 0 or position is length

      if insertInMiddle or itemSelector
        # Get the children which originate from item views.
        children = filterChildren list.children, itemSelector
        childrenLength = children.length

        # Check if it needs to be inserted.
        unless children[position] is viewEl
          if isEnd childrenLength
            # Insert at the end.
            list.appendChild viewEl
          else if position is 0
            # Insert at the right position.
            list.insertBefore viewEl, children[position]
          else
            last = children[position - 1]
            if list.lastChild is last
              list.appendChild viewEl
            else
              list.insertBefore viewEl, last.nextElementSibling
      else if isEnd length
        list.appendChild viewEl
      else
        list.insertBefore viewEl, list.firstChild

# General class for rendering Collections.
# Derive this class and declare at least `itemView` or override
# `initItemView`. `initItemView` gets an item model and should instantiate
# and return a corresponding item view.
module.exports = class CollectionView extends View
  # Configuration options
  # =====================

  # These options may be overwritten in derived classes.

  # A class of item in collection.
  # This property has to be overridden by a derived class.
  itemView: null

  # Automatic rendering
  # -------------------

  # Per default, render the view itself and all items on creation.
  autoRender: true
  renderItems: true

  # Animation
  # ---------

  # When new items are added, their views are faded in.
  # Animation duration in milliseconds (set to 0 to disable fade in)
  animationDuration: 500

  # By default, fading in is done by javascript function which can be
  # slow on mobile devices. CSS animations are faster,
  # but require user’s manual definitions.
  useCssAnimation: false

  # CSS classes that will be used when hiding / showing child views.
  animationStartClass: 'animated-item-view'
  animationEndClass: 'animated-item-view-end'

  # Selectors and elements
  # ----------------------

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
  # If empty, all children of $list are considered.
  # Not null, because of Zepto bug https://github.com/madrobby/zepto/pull/768.
  itemSelector: undefined

  # Filtering
  # ---------

  # The filter function, if any.
  filterer: null

  # A function that will be executed after each filter.
  # Hides excluded items by default.
  filterCallback: (view, included) ->
    view.$el.stop(true, true) if $
    toggleElement (if $ then view.$el else view.el), included

  # View lists
  # ----------

  # Track a list of the visible views.
  visibleItems: null

  # Constructor
  # -----------

  optionNames: View::optionNames.concat ['renderItems', 'itemView']

  constructor: (options) ->
    # Initialize list for visible items.
    @visibleItems = []

    super

  # Initialization
  # --------------

  initialize: (options = {}) ->
    # Don't call super; the base view's initialize is a no-op.

    # Start observing the collection.
    @addCollectionListeners()

    # Apply a filter if one provided.
    @filter options.filterer if options.filterer?

  # Binding of collection listeners.
  addCollectionListeners: ->
    @listenTo @collection, 'add', @itemAdded
    @listenTo @collection, 'remove', @itemRemoved
    @listenTo @collection, 'reset sort', @itemsReset

  # Rendering
  # ---------

  # Override View#getTemplateData, don’t serialize collection items here.
  getTemplateData: ->
    templateData = {length: @collection.length}

    # If the collection is a SyncMachine, add a `synced` flag.
    if typeof @collection.isSynced is 'function'
      templateData.synced = @collection.isSynced()

    templateData

  # In contrast to normal views, a template is not mandatory
  # for CollectionViews. Provide an empty `getTemplateFunction`.
  getTemplateFunction: ->

  # Main render method (should be called only once)
  render: ->
    super

    # Set the $list property with the actual list container.
    if $
      @$list = if @listSelector then @$(@listSelector) else @$el
    else
      @list = if @listSelector then @find(@listSelector) else @el

    @initFallback()
    @initLoadingIndicator()

    # Render all items.
    @renderAllItems() if @renderItems

  # Adding / Removing
  # -----------------

  # When an item is added, create a new view and insert it.
  itemAdded: (item, collection, options) =>
    @insertView item, @renderItem(item), options.at

  # When an item is removed, remove the corresponding view from DOM and caches.
  itemRemoved: (item) =>
    @removeViewForItem item

  # When all items are resetted, render all anew.
  itemsReset: =>
    @renderAllItems()

  # Fallback message when the collection is empty
  # ---------------------------------------------

  initFallback: ->
    return unless @fallbackSelector

    # Set the $fallback property.
    if $
      @$fallback = @$ @fallbackSelector
    else
      @fallback = @find @fallbackSelector

    # Listen for visible items changes.
    @on 'visibilityChange', @toggleFallback

    # Listen for sync events on the collection.
    @listenTo @collection, 'syncStateChange', @toggleFallback

    # Set visibility initially.
    @toggleFallback()

  # Show fallback if no item is visible and the collection is synced.
  toggleFallback: =>
    visible = @visibleItems.length is 0 and (
      if typeof @collection.isSynced is 'function'
        # Collection is a SyncMachine.
        @collection.isSynced()
      else
        # Assume it is synced.
        true
    )
    toggleElement (if $ then @$fallback else @fallback), visible

  # Loading indicator
  # -----------------

  initLoadingIndicator: ->
    # The loading indicator only works for Collections
    # which are SyncMachines.
    return unless @loadingSelector and
      typeof @collection.isSyncing is 'function'

    # Set the $loading property.
    if $
      @$loading = @$ @loadingSelector
    else
      @loading = @find @loadingSelector

    # Listen for sync events on the collection.
    @listenTo @collection, 'syncStateChange', @toggleLoadingIndicator

    # Set visibility initially.
    @toggleLoadingIndicator()

  toggleLoadingIndicator: ->
    # Only show the loading indicator if the collection is empty.
    # Otherwise loading more items in order to append them would
    # show the loading indicator. If you want the indicator to
    # show up in this case, you need to overwrite this method to
    # disable the check.
    visible = @collection.length is 0 and @collection.isSyncing()
    toggleElement (if $ then @$loading else @loading), visible

  # Filtering
  # ---------

  # Filters only child item views from all current subviews.
  getItemViews: ->
    itemViews = {}
    if @subviews.length > 0
      for name, view of @subviewsByName when name.slice(0, 9) is 'itemView:'
        itemViews[name.slice(9)] = view
    itemViews

  # Applies a filter to the collection view.
  # Expects an iterator function as first parameter
  # which need to return true or false.
  # Optional filter callback which is called to
  # show/hide the view or mark it otherwise as filtered.
  filter: (filterer, filterCallback) ->
    # Save the filterer and filterCallback functions.
    @filterer = filterer
    @filterCallback = filterCallback if filterCallback
    filterCallback ?= @filterCallback

    hasItemViews = do =>
      if @subviews.length > 0
        for name of @subviewsByName when name.slice(0, 9) is 'itemView:'
          return true
      false

    # Show/hide existing views.
    if hasItemViews
      for item, index in @collection.models

        # Apply filter to the item.
        included = if typeof filterer is 'function'
          filterer item, index
        else
          true

        # Show/hide the view accordingly.
        view = @subview "itemView:#{item.cid}"
        # A view has not been created for this item yet.
        unless view
          throw new Error 'CollectionView#filter: ' +
            "no view found for #{item.cid}"

        # Show/hide or mark the view accordingly.
        @filterCallback view, included

        # Update visibleItems list, but do not trigger an event immediately.
        @updateVisibleItems view.model, included, false

    # Trigger a combined `visibilityChange` event.
    @trigger 'visibilityChange', @visibleItems

  # Item view rendering
  # -------------------

  # Render and insert all items.
  renderAllItems: =>
    items = @collection.models

    # Reset visible items.
    @visibleItems = []

    # Collect remaining views.
    remainingViewsByCid = {}
    for item in items
      view = @subview "itemView:#{item.cid}"
      if view
        # View remains.
        remainingViewsByCid[item.cid] = view

    # Remove old views of items not longer in the list.
    for own cid, view of @getItemViews() when cid not of remainingViewsByCid
      # Remove the view.
      @removeSubview "itemView:#{cid}"

    # Re-insert remaining items; render and insert new items.
    for item, index in items
      # Check if view was already created.
      view = @subview "itemView:#{item.cid}"
      if view
        # Re-insert the view.
        @insertView item, view, index, false
      else
        # Create a new view, render and insert it.
        @insertView item, @renderItem(item), index

    # If no view was created, trigger `visibilityChange` event manually.
    @trigger 'visibilityChange', @visibleItems if items.length is 0

  # Instantiate and render an item using the `viewsByCid` hash as a cache.
  renderItem: (item) ->
    # Get the existing view.
    view = @subview "itemView:#{item.cid}"

    # Instantiate a new view if necessary.
    unless view
      view = @initItemView item
      # Save the view in the subviews.
      @subview "itemView:#{item.cid}", view

    # Render in any case.
    view.render()

    view

  # Returns an instance of the view class. Override this
  # method to use several item view constructors depending
  # on the model type or data.
  initItemView: (model) ->
    if @itemView
      new @itemView {autoRender: false, model}
    else
      throw new Error 'The CollectionView#itemView property ' +
        'must be defined or the initItemView() must be overridden.'

  # Inserts a view into the list at the proper position.
  insertView: (item, view, position, enableAnimation = true) ->
    enableAnimation = false if @animationDuration is 0

    # Get the insertion offset if not given.
    unless typeof position is 'number'
      position = @collection.indexOf item

    # Is the item included in the filter?
    included = if typeof @filterer is 'function'
      @filterer item, position
    else
      true

    # Get the view’s top element.
    elem = if $ then view.$el else view.el

    # Start animation.
    if included and enableAnimation
      startAnimation elem, @useCssAnimation, @animationStartClass

    # Hide or mark the view if it’s filtered.
    @filterCallback view, included if @filterer

    length = @collection.length

    # Insert the view into the list.
    list = if $ then @$list else @list

    insertView list, elem, position, length, @itemSelector

    # Tell the view that it was added to its parent.
    view.trigger 'addedToParent'

    # Update the list of visible items, trigger a `visibilityChange` event.
    @updateVisibleItems item, included

    # End animation.
    if included and enableAnimation
      if @useCssAnimation
        # Wait for DOM state change.
        setTimeout (=> addClass elem, @animationEndClass), 0
      else
        # Fade the view in if it was made transparent before.
        endAnimation elem, @animationDuration

    view

  # Remove the view for an item.
  removeViewForItem: (item) ->
    # Remove item from visibleItems list, trigger a `visibilityChange` event.
    @updateVisibleItems item, false
    @removeSubview "itemView:#{item.cid}"

  # List of visible items
  # ---------------------

  # Update visibleItems list and trigger a `visibilityChanged` event
  # if an item changed its visibility.
  updateVisibleItems: (item, includedInFilter, triggerEvent = true) ->
    visibilityChanged = false

    visibleItemsIndex = utils.indexOf @visibleItems, item
    includedInVisibleItems = visibleItemsIndex isnt -1

    if includedInFilter and not includedInVisibleItems
      # Add item to the visible items list.
      @visibleItems.push item
      visibilityChanged = true
    else if not includedInFilter and includedInVisibleItems
      # Remove item from the visible items list.
      @visibleItems.splice visibleItemsIndex, 1
      visibilityChanged = true

    # Trigger a `visibilityChange` event if the visible items changed.
    if visibilityChanged and triggerEvent
      @trigger 'visibilityChange', @visibleItems

    visibilityChanged

  # Disposal
  # --------

  dispose: ->
    return if @disposed

    # Remove jQuery objects, item view cache and visible items list.
    properties = ['$list', '$fallback', '$loading', 'visibleItems']
    delete this[prop] for prop in properties

    # Self-disposal.
    super
