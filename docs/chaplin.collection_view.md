---
layout: default
title: Chaplin.CollectionView
module_path: src/chaplin/views/collection_view.coffee
---

The `CollectionView` is responsible for displaying collections. For every item in a collection, it instantiates a given item view and inserts it into the DOM. It reacts to collection change events (`add`, `remove` and `reset`) and provides basic filtering, caching of views, fallback content and loading indicators.

<h2 id="properties">Properties</h2>

<h3 class="module-member" id="itemView">itemView</h3>
* **a View that extends from Chaplin.View (default null)**

  Your item View class, which will represent the individual items
  in the collection

<h3 class="module-member" id="autoRender">autoRender</h3>
* **boolean (default true)**

  Render the view automatically on instantiation. This overrides
  Chaplin.View's default of false. Your inheriting classes (and
  instatiated objects via the options hash) can set their own value.

<h3 class="module-member" id="renderItems">renderItems</h3>
* **boolean (default true)**

  Should the view automatically render all items on instantiation?

  Can be passed during instantiation via the options hash.

<h3 class="module-member" id="animationDuration">animationDuration</h3>
* **int, duration in ms (default 500)**

  When new items are added, their views are faded in over a period of
  `animationDuration` milliseconds. Set to 0 to disable fade in.

<h3 class="module-member" id="listSelector">listSelector</h3>
* **string (default null)**

  Specifies a selector for container of all item views.
  If empty, current view $el is used.

<h3 class="module-member" id="itemSelector">itemSelector</h3>
* **string (default null)**

  Selector which identifies child elements belonging to collection.
  If empty, all children of listSelector are considered.

<h3 class="module-member" id="loadingSelector">loadingSelector</h3>
* **string (default null)**

  Selector for a loading indicator element which is shown
  while the collection is syncing.

<h3 class="module-member" id="fallbackSelector">fallbackSelector</h3>
* **string (default null)**

  Selector for a fallback element which is shown if the collection is empty.

<h3 class="module-member" id="useCssAnimation">useCssAnimation</h3>
* **boolean (default false)**

  By default, fading in is done by javascript function which can be
  slow on mobile devices. CSS animations are faster,
  but require user’s manual definitions.

<h3 class="module-member" id="animationStartClass">animationStartClass</h3>
* **string (default `animated-item-view`)**

  CSS classes that will be used when hiding / showing child views starts.

<h3 class="module-member" id="animationEndClass">animationEndClass</h3>
* **string (default `animated-item-view-end`)**

  CSS classes that will be used when hiding / showing child views ends.

<h2 id="methods">Methods</h2>
  Most of CollectionView's methods should not need to be called
  externally. Modifying the underlying collection will automatically
  update the items on screen (for instance, fetching more models
  from the server), as the view listens for `add`, `remove`, and
  `reset` events by default.

<h3 class="module-member" id="initialize">initialize([options={}])</h3>
* **options**
    * **renderItems** see [renderItems](#renderItems)
    * **itemView** see [itemView](#itemView)
    * **filterer** automatically calls [filter](#filter) if set
    * all [View](./chaplin.view.html#initialize) and standard
      [Backbone.View](http://backbonejs.org/#View-constructor) options

<h3 class="module-member" id="filter">filter([filterer, [filterCallback]])</h3>
* **function filterer (see below)**
* **function filterCallback (see below)**

  Calling `filter` directly with a `filterer` and `filterCallback` overrides
  the CollectionView's instance variables with these arguments.

  Called with no arguments is a no-op

<h3 class="module-member" id="filterer">filterer(item, index)</h3>
* **Model item**
* **int index of item in collection**
* **returns boolean: is item included?**

  A iterator function that determines which items are shown. Can be passed
  in during instantiation via `options`. The function is optional; if not
  set all items will be included.

#### Example

```coffeescript
filterer: (item, index) ->
  item.get 'color' is 'red'

...

filterer: (item, index) ->
  index < 20 if @limit? else true
```

```javascript
filterer: function(item, index) {
  return item.get('color') === 'red';
}
...

filterer: function(item, index) {
  return (this.limit != null) ? index < 20 : true;
}
```

<h3 class="module-member" id="filterCallback">filterCallback(view, included)</h3>
* **View view**
* **boolean included**

  Called on each item in the collection during filtering

  Default is to hide excluded views

#### Example

```coffeescript
filterCallback: (view, included) ->
  view.$el.toggleClass('active', included)

...

filterCallback: (view, included) ->
  opts = if included then 'long-title, large-thumbnail' else 'short-title, small-thumbnail'
  view.showExtendedOptions(opts)
```

```javascript
filterCallback: function(view, included) {
  view.$el.toggleClass('active', included);
}

...

filterCallback: function(view, included) {
  var opts = (included) ? 'long-title, large-thumbnail' : 'short-title, small-thumbnail';
  view.showExtendedOptions(opts);
}
```

<h3 class="module-member" id="addCollectionListeners">addCollectionListeners()</h3>

  By default adds event listeners for `add`, `remove`, and `reset` events. Can
  be extended to track more events.

<h3 class="module-member" id="getItemViews">getItemViews()</h3>

  Returns a hash of views, keyed by their `cid` property

<h3 class="module-member" id="renderAllItems">renderAllItems()</h3>

  Render and insert all items in collection, triggering `visibilityChange` event

<h3 class="module-member" id="renderItem">renderItem(model)</h3>
* **Model item**

  Instantiate and render the view for an item using the `viewsByCid`
  hash as a cache.

<h3 class="module-member" id="initItemView">initItemView(model)</h3>
* **Model model**

  Returns an instance of the view class (as determined by `@itemView`).
  Override this method to use several item view constructors depending
  on the model type or data.

<h3 class="module-member" id="insertView">insertView(item, view, [index], [enableAnimation])</h3>
* **Model item**
* **View view**
* **int index (if unset will search through collection)**
* **boolean enableAnimation (default true)**

  Inserts a view into the list at the proper position, runs the `@filterer`
  function.

<h3 class="module-member" id="removeViewForItem">removeViewForItem(model)</h3>
* **Model item**

  Remove the view for an item, triggering a `visibilityChange` event

<h3 class="module-member" id="updateVisibleItems">updateVisibleItems(item, [includedInFilter], [triggerEvent])</h3>
* **Model item**
* **boolean includedInFilter**
* **triggerEvent (default true)**

  Update visibleItems list and trigger a `visibilityChanged` event
  if an item changed its visibility


## Usage
Most inheriting classes of CollectionView should be very small, with
the majority of implementations only needing to overwrite the itemView
property. Standard View conventions like adding `@listenTo` handlers
should still take place in `initialize`, but the majority of Collection-
specific logic is handled by this class.

#### Example

```coffeescript
class LikesView extends CollectionView
  autoRender: true
  className: 'likes-list'
  itemView: LikeView
  tagName: 'ul'
```

```javascript
var LikesView = CollectionView.extend({
  autoRender: true,
  className: 'likes-list',
  itemView: LikeView,
  tagName: 'ul'
});
```

### Real World Examples

* [Ost.io PostsView](https://github.com/paulmillr/ostio/blob/master/app/views/post/posts-view.coffee)
* [Facebook LikesView](https://github.com/chaplinjs/facebook-example/blob/master/coffee/views/likes_view.coffee)
* [FarmTab CustomersView](https://github.com/akre54/FT/blob/master/app/views/customers_collection_view.coffee)
