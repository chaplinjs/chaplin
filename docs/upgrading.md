---
layout: default
title: Upgrading guide
Chaplin: Upgrading guide
---

### Upgrading to 0.12
* Replace all references to `Chaplin.helpers` with `Chaplin.utils`.
* If you are using Delayer, make sure to include [separate Delayer package](https://github.com/chaplinjs/delayer) — it has been removed from Chaplin core.
* If you are using Exoskeleton, make sure to upgrade to v0.6.

### Upgrading to 0.11
* Change controller action param order: from (`params, route, options`), query string URL will no longer reside in `params`.
  `/users/paulmillr?popup=1` (assuming `/users/:name` route) will pass:
    * Before: `params={name: 'paulmillr', popup: '1'}`
    * Now: `params={name: 'paulmillr'}, options={query=popup: '1'}`
* Rename `Application#startRouting` to `Application#start`
  (the following method also does freezing of app object).
* Since `!event` pattern was replaced with *Request / Response*,
  stop publishing various global events:
    * Instead of `!router:route` and `!router:routeByName`,
      use `Chaplin.helpers.redirectTo`.
    * Instead of `!router:changeURL` event,
      execute mediator handler: `mediator.execute('router:changeURL', args...)`
    * Instead of `!adjustTitle` event,
      execute mediator handler: `mediator.execute('adjustTitle', name)`
    * Instead of `!composer:compose` / `!composer:retrieve` events,
      use `mediator.execute('composer:compose')` / `mediator.execute('composer:retrieve')`
    * Instead of `!region:register` / `!region:unregister` events,
      use `mediator.execute('region:register')` / `mediator.execute('region:unregister')`
* Replace `Controller#redirectToRoute(name)` with
  `Controller#redirectTo(name)`
* Replace `Controller#redirectTo(url)` with
  `Controller#redirectTo({url: url})`.
* Keep in mind that `Controller#compose` now:
    * by default, returns the composition itself
    * if composition body returned a promise, it returns a promise too

### Upgrading to 0.10
* Replace `application = new Chaplin.Application(); application.initialize()` with `new Chaplin.Application`: `initialize` is now called by default.
* `Application#initialize` now has default functionality,
  make sure to adjust `super` calls.
* Swap view regions syntax to more logical:
    * Before: `regions: {'.selector': 'region'}`.
    * Now: `regions: {'region': '.selector'}`.
* Make sure to remove `callback` argument from `!router:route` and
  `!router:routeByName` event calls — it is synchronous now.

### Upgrading to 0.9
* `Controller#beforeAction` must now be a function instead of
  an object.
* Remove `initDeferred` method calls from Models and Collections
  (or provide your own).
* Make sure to adjust your routes: `deleted_users#show` won’t longer be rewritten to `deletedUsers#show`
* Rename methods in your `Layout` subclass (if you're subclassing it):
    * `_registeredRegions` to `globalRegions`
    * `registerRegion` to `registerGlobalRegion`
    * `registerRegion` to `registerGlobalRegions`
    * `unregisterRegion` to `unregisterGlobalRegion`
    * `unregisterRegions` to `unregisterGlobalRegions`
* Provide your own `utils.underscorize`.

### Upgrading to 0.8
*`Application#initRouter`.
      `Application#startRouting`
* Adjust your controller actions params to
  `params, route, options` instead of `params, options`.
* Remove RegExp routes. Use `constraints` route param and strings instead.
* Rename `matchRoute` global event to `router:match`
* Rename `startupController` global event to `dispatcher:dispatch`
* If you are subclassing `Dispatcher`, many methods now
  receive `route` too.

### Upgrading to 0.7
* Change your controller action params: instea dof
  `params, previousControllerName`, use
  `params, options={previousControllerName, path...}`
* Change `View`:
    * Rename `View#afterRender` to `View#attach`.
    * Remove `View#afterInitialize`.
    * Remove `View#pass`.
* Change `CollectionView`:
    * Rename `CollectionView#itemsResetted` to `CollectionView#itemsReset`.
    * Rename `CollectionView#getView` to `CollectionView#initItemView`.
    * Rename `CollectionView#showHideFallback` to `CollectionView#toggleFallback`.
    * Rename `CollectionView#showHideLoadingIndicator` to `CollectionView#toggleLoadingIndicator`.
    * Remove `CollectionView#renderAndInsertItem`.
    * Item views will now emit `addedToParent` event instead of `addedToDOM`
    when they are appended to collection view.
* Don't use `utils.wrapMethod` (or provide your own).
