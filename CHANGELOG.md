# Chaplin 0.11.0 (21 September 2013)
* Chaplin internals now use *Request / Response* pattern instead of
  bang `!events`. New system also allows to return values.
  The syntax is so: `mediator.setHandler(name, function)`,
  `mediator.execute(name, args...)`.
  Removed events:
    * `!router:route`, `!router:routeByName` (use `helpers.redirectTo`)
    * `!router:changeURL`
    * `!composer:compose`, `!composer:retrieve`
    * `!region:register`, `!region:unregister`
    * `!adjustTitle`
      (use `mediator.execute('adjustTitle', name)` or `Controller#adjustTitle`).
      An `adjustTitle` event would be triggered after title is set.
* Improved `Chaplin.Controller`:
    * `Controller::compose` method now:
        * by default, returns the composition itself
        * if composition body returned a promise, it returns a promise too
    * Removed `Controller#redirectToRoute`. Use `Controller#redirectTo`.
    * `redirectTo` now takes route name by default. If you want to pass URL, use it as `redirectTo({url: 'URL'})`.
* Improved `Chaplin.View`:
    * Added `noWrap` option that allows to disable Backbone top-level
      element bound to view class.
    * Added `optionNames` property that contains a list of options that will
      be picked from an object passed to View, when initialising it.
      Property allows to simply extend it in your child classes:
      `optionNames: ParentView.prototype.optionNames.concat(['template'])`
    * Views now appended to DOM only if they were not there.
* Improved `Chaplin.Layout`:
    * When push state is disabled, internal links are handled as if they had `#` (gh-664).
* Improved `Chaplin.helpers`:
    * Added `helpers.redirectTo` which allows to redirect to other route
      or url.
* Improved `Chaplin.utils`:
    * Added `utils.queryParams.{stringify,parse}`.
    * `utils.getPrototypeChain` now returns prototypes from
      oldest to newest, to match `utils.getAllPropertyVersions`.
* Improved `Chaplin.Router`:
    * `Route::reverse` (as well as `Router::reverse`) are now able to add query parameters to the reversed URL, no matter if they are already stringified or not when passed into the reverse (as a third parameter).
    * `Route::matches` improved not to return `true` when the only `controller` or `action` parameter passed.
    * Fixed `getCurrentQuery` error when `pushState` is disabled (gh-671).
    * Query params are now not copied to next routes (gh-677).
* Improved `Chaplin.Application`:
    * Renamed `startRouting` to `start`, the following method also does freezing of app object.
* Temporarily added `Chaplin.History` that overrides `Backbone.History`.
  It won't not ignore query string history as compared to Backbone (gh-577).

Special thanks to [Andrew Yankovsky](https://github.com/YAndrew91).

# Chaplin 0.10.0 (30 June 2013)
Chaplin now provides universal build for Common.js and AMD.

* Improved `Chaplin.Application`:
    * Application is now initialized by default with `new Application`
      constructor method instead of `Application#initialize`.
    * Added default `Application#initialize` functionality.
* Improved `Chaplin.Router`:
    * Early error is now thrown for `!router:route`, `!router:routeByName`
      and Chaplin.helpers.reverse methods when nothing is matched.
    * Removed `callback` argument from `!router:route` and
      `!router:routeByName`.
* Improved `Chaplin.View`:
    * **Breaking:** `regions` syntax has changed to more logical.
      Before: `regions: {'.selector': 'region'}`.
      Now: `regions: {'region': '.selector'}`.
      We’ve made a small utility that automatically updates your code
      to new syntax: [replace.js](https://gist.github.com/paulmillr/5891455).
      Also, updated `registerRegion` method signature to similar.
    * `regions` option can now be passed to constructor.
    * `insertView` now returns inserted view.
* Fix controller disposal after redirect.

# Chaplin 0.9.0 (4 May 2013)
* Added full lodash compatibility.
* Removed deferred mix-in (`initDeferred`) support from
  models, collections and views.
* Improved `Chaplin.Controller` and `Chaplin.Dispatcher`:
    * Made `Controller#beforeAction` a function.
      The old object form is not supported anymore.
      You need to use `super` like in any other method,
      `beforeAction`s won’t be merged without it.
      Asyncronous `beforeAction`s with promises are still supported.
    * Controllers are now disposed automatically after redirection
      or asynchronous before actions.
* Improved `Chaplin.Router`:
    * Fixed bug with preserving query string in URL.
    * Removed underscorizing of loaded by default controller names.
      `deleted_users#show` won’t longer be rewritten to `deletedUsers#show`.
      The controller name in the route is directly used as module name.
* Improved `Chaplin.View`:
    * Added `keepElement` property (false by default).
      When truthy, the view’s DOM element won’t be removed after disposal.
    * `View#dispose` now calls Backbone’s `View#remove` method.
    * Subviews are now always an array.
* Improved `Chaplin.CollectionView`:
    * Added Backbone 1.0 `Collection#set` support.
* Improved `Chaplin.Layout`:
    * Added inheritance from `Chaplin.View`.
    * Renamed some methods for compat with `Chaplin.View`:
        * `_registeredRegions` to `globalRegions`
        * `registerRegion` to `registerGlobalRegion`
        * `registerRegion` to `registerGlobalRegions`
        * `unregisterRegion` to `unregisterGlobalRegion`
        * `unregisterRegions` to `unregisterGlobalRegions`
    * Changed default `Layout` element from `document` to `body`.
    * Removed explicit `view.$el.show()` / `hide()` for managed views.
    * Removed `route` property. Use `settings.routeLinks` instead.
* Improved `Chaplin.utils`:
    * Removed `underscorize`.

# Chaplin 0.8.1 (1 April 2013)
* Improved `Chaplin.Layout`:
    * Added `Layout#$` method, which is the same as `View#$`.
      This also fixes how regions behave in Layout.
* Improved `Chaplin.View`:
    * The check is now done when listening to collection `dispose`
      event whether it really came from collection and not from its
      model.

# Chaplin 0.8.0 (31 March 2013)
* Added `Chaplin.helpers` component. It contains Chaplin-related
  functions. `Chaplin.utils` will contain generic functions.
    * `helpers.reverse` allows to get route URL by its name and params.
* Improved `Chaplin.Application`:
    * Separated router initialisation and start of listening for routing.
      The first one as before resides in `Application#initRouter`.
      `Application#startRouting`. You need to launch both.
      This is breaking change and without it your app will not start routing.
* Improved `Chaplin.Controller`:
    * All actions are now initialised with `params, route, options`
      instead of `params, options`. New `route` argument contains
      information about current route (`controller, action, name, path`)
      and about previous (`route.previous`) and `options` just contain
      options, passed to `Backbone.history.navigate`.
    * When using redirection in actions, controller will automatically
      dispose redirected controller.
* Improved `Chaplin.Router`:
    * All routes now have default names in format of
      (controller + '#' + action).
    * `Router#reverse` will now prepend mount point.
    * Removed RegExp routes. Use `constraints` route param and strings instead.
* Improved `Chaplin.Layout`:
    * Allowed registering regions.
    * Added `Layout#isExternalLink` that is used when clicking on any event
      and checks if current one is application-related.
* Improved `Chaplin.View`:
    * If `autoAttach` option is false, view will not be added to container.
    * Empty-selector regions are now considered as bound to root view element.
* Improved overall `View` and `CollectionView` performance for common cases.
* Improved internal API:
    * Renamed `matchRoute` global event to `router:match`
    * Renamed `startupController` global event to `dispatcher:dispatch`
    * Changed signatures of many `Dispatcher` methods, they now
      pass `route` too.

# Chaplin 0.7.0 (19 February 2013)
* Added support of regions and regions composition with `Chaplin.Composer`.
  Composer grants the ability for views (and related data) to be
  persisted beyond one controller action.
* Improved `Chaplin.Controller`:
    * Query string params are now passed to controllers
      (a feature removed from Backbone 0.9.9).
    * Controller actions will now receive an `options` hash
      as second argument, that contains `path`, `previousControllerName`
      and routing options. Previously, the second argument was just
      a `previousControllerName` string.
    * Fixed `Controller#redirectTo` signature (`url, options`).
    * `Controller#dispose` will now unbind all events bound by `listenTo` method.
* Improved `Chaplin.Dispatcher`:
    * Stop waiting for a Promise returned by a before action when another route is dispatched
      or the same is dispatched again.
* Improved `Chaplin.Router`:
    * The `params` and `options` objects are copied instead of changed to prevent conflicts.
      If you pass `params` and `options` along with the `!router:route` event,
      the controller action will receive a copy of them. Same for `Dispatcher`.
    * Fixed `root` option.
    * Fixed route reversals on empty patterns (for example, the top-level route).
* Improved `Chaplin.Collection`:
    * `Collection#dispose` will now unbind all events bound by `listenTo` method.
    * Removed `Collection#addAtomic` as it was barely used.
* Improved `Chaplin.Model`:
    * `Model#serialize` can be overridden on `Backbone.Model`s.
      Chaplin will use it, if available, and `Model#toJSON` if not.
    * `Model#dispose` will now unbind all events bound by `listenTo` method.
    * Improved time complexity of `Model#serialize` from O(n) to amortized O(1).
* Improved `Chaplin.utils`:
    * Added `utils.getAllPropertyVersions` that allows to gather all
      property versions from object’s prototypes.
    * Added `utils.escapeRegExp` that escapes all regular expression characters
    in string.
    * Removed `utils.wrapMethod`.
* Improved `Chaplin.View`:
    * Added `View#listen` property that allows to declaratively listen to
      model / collection / mediator / view events.
      Just like Backbone’s `View#events`, which is only for DOM events.
    * Added new `autoAttach` option which determines whether
      view should be automatically attached to DOM after render.
    * Renamed `View#afterRender` to `View#attach`.
    * Removed `View#afterInitialize`.
    * Removed `View#pass`. Please use
      [stickit](http://nytimes.github.com/backbone.stickit/) instead
      for advanced model-view binding.
    * Switched to `$el.toggle()` instead of manual CSS `display` setting.
    Which means non-block elements will behave correctly.
    * Switched to `Backbone.$` reference for DOM manipulation.
      This will automatically use jQuery, Zepto or Ender as DOM library.
    * Early error is now thrown when `View#events` is a function.
* Improved `Chaplin.CollectionView`:
    * Renamed `CollectionView#itemsResetted` to `CollectionView#itemsReset`.
    * Renamed `CollectionView#getView` to `CollectionView#initItemView`.
    * Renamed `CollectionView#showHideFallback` to `CollectionView#toggleFallback`.
    * Renamed `CollectionView#showHideLoadingIndicator` to `CollectionView#toggleLoadingIndicator`.
    * Removed `CollectionView#renderAndInsertItem`.
    * Item views will now be called with `autoRender: false`, which prevents rendering them twice.
    * Item views will now emit `addedToParent` event instead of `addedToDOM`
    when they are appended to collection view.
    * Optimised performance by not calling jQuery / Zepto `css` / `animate` when animations are disabled.

# Chaplin 0.6.0 (30 December 2012)
* Updated required Backbone version to 0.9.9+.
* Improved `Chaplin.Collection`:
    * Removed `Collection#update` since this function is now provided by Backbone itself
      (`Collection#update` in Backbone < 1.0, `Collection#set` in Backbone >= 1.0).
      The `deep` option is now called `merge` and it defaults to true.
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
* Improved `Chaplin.CollectionView`:
    * `CollectionView#getTemplateData` no longer returns `items` property,
    which increases performance.
* Router options are now allowed to be passed in many places.
  New signatures are:
    * `!router:route` global event: path, *options*, callback
      (old sig is supported too)
    * `Dispatcher#matchRoute`: route, params, *options*
    * `Controller#redirectTo`: path or
      (controllerName, action, params, *options*)

# Chaplin 0.5.0 (15 November 2012)
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

# Chaplin 0.4.0 (28 June 2012)
* A lot of various global changes.
* Added tests for all components.
* Chaplin now can be used as a standalone library.

# Chaplin 0.3.0 (23 March 2012)
* Bug fix: In CollectionView, get the correct item position when rendering
the item view. Fixes the rendering of sorted Collections. Before the fix,
the item views might have been displayed in the wrong order. (@rendez)

# Chaplin 0.2.0 (9 March 2012)
* Fixed correct unsubscribing of global handlers when disposing a collection.
* The codebase now uses consistent code style (@paulmillr).

# Chaplin 0.1.0 (26 February 2012)
* Initial release.
