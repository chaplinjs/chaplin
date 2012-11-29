# Chaplin.CollectionView

The `CollectionView` is responsible for displaying collections. For every item in a collection, it instantiates a given item view and inserts it into the DOM. It reacts to collection change events (`add`, `remove` and `reset`) and provides basic filtering, caching of views, fallback content and loading indicators.

## Properties of `Chaplin.CollectionView`

<a id="itemView"></a>
### itemView
* **a View that extends from Chaplin.View (default null)**

  Your item View class, which will represent the individual items
  in the collection

<a id="autoRender"></a>
### autoRender
* **boolean (default true)**

  Render the view automatically on instantiation. This overrides
  Chaplin.View's default of false. Your inheriting classes (and
  instatiated objects via the options hash) can set their own value.

<a id="renderItems"></a>
###  RenderItems
* **boolean (default true)**

  Should the view automatically render all items on instantiation?

  Can be passed during instantiation via the options hash.

<a id="animationDuration"></a>
### animationDuration
* **int, duration in ms (default 500)**

  When new items are added, their views are faded in over a period of
  `animationDuration` milliseconds. Set to 0 to disable fade in.

<a id="useCssAnimation"></a>
### useCssAnimation
* **boolean (default false)**

  By default, fading in is done by javascript function which can be
  slow on mobile devices. CSS animations are faster,
  but require user’s manual definitions.

  CSS classes used are: **animated-item-view**, **animated-item-view-end**.

<a id="methods-overview"></a>
## Methods of `Chaplin.CollectionView`
  Most of CollectionView's methods should not need to be called
  externally. Modifying the underlying collection will automatically
  update the items on screen (for instance, fetching more models
  from the server), as the view listens for `add`, `remove`, and
  `reset` events by default.

<a id="initialize"></a>
### initialize([options={}])
* **options**
    * **renderItems** see [renderItems](#renderItems)
    * **itemView** see [itemView](#itemView)
    * **filterer** automatically calls [filter](#filter) if set
    * all [View](./Chaplin.View.md#initialize) and standard
    [Backbone.View](http://backbonejs.org/#View-constructor) options

<a id="filter"></a>
### filter([filterer, [filterCallback]])
* **function filterer (see below)**
* **function filterCallback (see below)**

  Calling `filter` directly with a `filterer` and `filterCallback` overrides
  the CollectionView's instance variables with these arguments.

  Called with no arguments is a no-op

<a id="filterer"></a>
### filterer(item, index)
* **Model item**
* **int index of ***item*** in collection**
* **returns boolean: is item included?**

  A iterator function that determines which items are shown. Can be passed
  in during instantiation via `options`. The function is optional; if not
  set all items will be included.

```coffeescript
filterer: (item, index) ->
  item.get 'color' is 'red'

...

filterer: (item, index) ->
  index < 20 if @limit? else true

```

<a id="filterCallback"></a>
### filterCallback(view, included)
* **View view**
* **boolean included**

  Called on each item in the collection during filtering

  Default is to hide excluded views

```coffeescript
filterCallback: (view, included) ->
  view.$el.toggleClass('active', included)

...

filterCallback: (view, included) ->
  opts = if included then 'long-title, large-thumbnail' else 'short-title, small-thumbnail'
  view.showExtendedOptions(opts)
```

<a id="addCollectionListeners"></a>
### addCollectionListeners()

  By default adds event listeners for `add`, `remove`, and `reset` events. Can
  be extended to track more events.

<a id="getItemViews"></a>
### getItemViews()

  Returns a hash of views, keyed by their `cid` property

<a id="renderAllItems"></a>
### renderAllItems()

  Render and insert all items in collection, triggering `visibilityChange` event

<a id="renderAndInsertItem"></a>
### renderAndInsertItem(item, index)
* **Model item**
* **int index**

  a composite of [`@renderItem()`](#renderItem) and [`@insertView()`](#insertView)

<a id="renderItem"></a>
### renderItem(item)
* **Model item**

  Instantiate and render the view for an item using the `viewsByCid`
  hash as a cache.

<a id="getView"></a>
### getView(model)
* **Model model**

  Returns an instance of the view class (as determined by `@itemView`).
  Override this method to use several item view constructors depending
  on the model type or data.

<a id="insertView"></a>
### insertView(item, view, [index], [enableAnimation])
* **Model item**
* **View view**
* **int index (if unset will search through collection)**
* **boolean enableAnimation (default true)**

  Inserts a view into the list at the proper position, runs the `@filterer`
  function.

<a id="removeViewForItem"></a>
### removeViewForItem(item)
* **Model item**

  Remove the view for an item, triggering a `visibilityChange` event

<a id="updateVisibleItems"></a>
### updateVisibleItems(item, [includedInFilter], [triggerEvent])
* **Model item**
* **boolean includedInFilter**
* **triggerEvent (default true)**

  Update visibleItems list and trigger a `visibilityChanged` event
  if an item changed its visibility


## Usage
  Most inheriting classes of CollectionView should be very small, with
  the majority of implementations only needing to overwrite the itemView
  property. Standard View conventions like adding `@modelBind` handlers
  should still take place in `initialize`, but the majority of Collection-
  specific logic is handled by this class.

```coffeescript
class LikesView extends CollectionView
  tagname: 'ul'
  className: 'likes-list'
  itemView: LikeView
  autoRender: true
```

### Examples

  * [osti.io PostsView](https://github.com/paulmillr/ostio/blob/master/app/views/post/posts-view.coffee)
  * [Facebook LikesView](https://github.com/chaplinjs/facebook-example/blob/master/coffee/views/likes_view.coffee)
  * [FarmTab CustomersView](https://github.com/akre54/FT/blob/master/app/views/customers_collection_view.coffee)


## [Code](https://github.com/chaplinjs/chaplin/blob/master/src/chaplin/views/collection_view.coffee)
