# Chaplin 0.6.0 (December 30, 2012)
* Updated required Backbone version to 0.9.9+.
* Improved `Chaplin.Collection`:
    * Removed `Collection#update` since this function is now provided
      by Backbone itself. The `deep` option is now called `merge` and it
      defaults to true.
* Improved `Chaplin.CollectionView`:
    * `CollectionView#getTemplateData` no longer returns `items` property,
    which increases performance.
* Improved `Chaplin.Controller`:
    * Added Rails-like before action filters to `Controller`s.
    * Added `Controller#redirectToRoute` which works like
      `Controller#redirectTo`, but accepts route name instead of URL.
    * Added flexible `Controller#adjustTitle` method which sets window title.
    * Added `Backbone.Events` mix-in.
    * Removed `Controller#title` and `Controller#historyURL`.
    * Removed ability of redirecting to standalone controllers and action names
      in `Controller#redirectTo`.
* Improved `Chaplin.Router`:
    * Added support for named routes.
    * Added new global `!router:routeByName` event, which allows to
      navigate to some route by its reverse name.
    * Added new global `!router:reverse` event, which allows to get
      URL of route by its name.
    * Added `names` option to `Router#match`, which allows to name
      route’s regular expression matches.
    * Removed global `!startupController` event.
* Improved `Chaplin.View`:
    * Removed `View#modelBind`, `View#modelUnbind` and `View#modelUnbindAll`,
      since Backbone now implements superior `Events.listenTo` API.
    * Chaplin will now fix incorrect inheritance of view DOM events,
      bound in declarative manner (with `events` hash).
    * Moved `View#wrapMethod` to `Chaplin.utils.wrapMethod`.
    * `View#dispose` will now throw an error if
      `View#initialize` was called without `super`.
* Router options are now allowed to be passed in many places.
  New signatures are:
    * `!router:route` global event: path, *options*, callback
      (old sig is supported too)
    * `Dispatcher#matchRoute`: route, params, *options*
    * `Controller#redirectTo`: path or
      (controllerName, action, params, *options*)

# Chaplin 0.5.0 (November 15, 2012)
* Improved and stabilized codebase.
* Moved `Chaplin.Subscriber` to `Chaplin.EventBroker`, which now mixins
  `publishEvent` method to children.
* Added `Chaplin.Delayer`, which sets unique and named timeouts and intervals
  so they can be cleared afterwards when disposing objects.
* Added `autoRender` option to `Chaplin.CollectionView`, like `Chaplin.View`.
  Defaults to true, replaces old `render` option.
* Added `serialize` method to collections
* Removed `CollectionView#viewsByCid` and `CollectionView#removeView` in favor
of consistent `View#subview` and `View#removeSubview`.
* Removed `CollectionView#initSyncMachine`.
* Removed `trigger`, `on` and `off` methods from `Chaplin.mediator`.
* Allowed passing of multiple event types to `View#delegate`.
* Made various aspects of `Chaplin.Layout` configurable.

# Chaplin 0.4.0 (June 28, 2012)
* A lot of various global changes.
* Added tests for all components.
* Chaplin now can be used as a standalone library.

# Chaplin 0.3.0 (March 23, 2012)
* Bug fix: In CollectionView, get the correct item position when rendering
the item view. Fixes the rendering of sorted Collections. Before the fix,
the item views might have been displayed in the wrong order. (@rendez)

# Chaplin 0.2.0 (March 09, 2012)
* Fixed correct unsubscribing of global handlers when disposing a collection.
* The codebase now uses consistent code style (@paulmillr).

# Chaplin 0.1.0 (February 26, 2012)
* Initial release.
