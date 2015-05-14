---
layout: default
title: Chaplin.Router
module_path: src/chaplin/lib/router.coffee
Chaplin: Router
---

This module is responsible for observing URL changes and matching them against a list of declared routes. If a declared route matches the current URL, a `router:match` event is triggered.

`Chaplin.Router` is a replacement for [Backbone.Router](http://documentcloud.github.com/backbone/#Router) and does not inherit from it. It is a stand-alone implementation with several advantages over Backbone’s default. Why change the router implementation completely?

In Backbone there are no controllers. Instead, Backbone’s `Router` maps routes to *its own methods*, serving two purposes and being more than just a router. Chaplin on the other hand delegates the handling of actions related to a specific route to controllers. Consequently, the router is really just a router. While the router has been rewritten for this purpose, Chaplin is using `Backbone.History` in the background. That is, Chaplin relies upon Backbone for handling hash URLs and interacting with the HTML5 History API (`pushState`).

## Declaring routes in the `routes` file

By convention, all application routes should be declared in a separate file, the `routes` module. This is a simple module in which a list of `match` statements serve to declare corresponding routes. For example:

```coffeescript
match '', 'home#index'
match 'likes/:id', controller: 'controllers/likes', action: 'show'
```

```javascript
match('', 'home#index');
match('likes/:id', {controller: 'controllers/likes', action: 'show'});
```

Ruby on Rails developers may find `match` intuitively familiar. For more information on its usage, [see below](#match). Internally, route objects representing each entry are created. If a route matches, a `router:match` event is published, passing the route object and a `params` hash which contains name-value pairs for named placeholder parts of the path description (like `id` in the example above), as well as additional GET parameters.

<h2 id="methods">Methods</h2>

<h3 class="module-member" id="createHistory">createHistory()</h3>
Creates the `Backbone.History` instance.

<h3 class="module-member" id="startHistory">startHistory()</h3>
Starts `Backbone.History` instance. This method should be called only after all routes have been registered.

<h3 class="module-member" id="stopHistory">stopHistory()</h3>
Stops the `Backbone.History` instance from observing URL changes.

<h3 class="module-member" id="match">match([pattern], [target], [options={}])</h3>

Connects a path with a controller action.

* **pattern** (String): A pattern to match against the current path.
* **target** (String): Specifies the controller action which is called if this route matches. Optionally, replaced by an equivalent description through the `options` hash.
* **options** (Object): optional

The `pattern` argument may contain named placeholders starting with a colon (`:`) followed by an identifier. For example, `'products/:product_id/ratings/:id'` will match the paths
`/products/vacuum-cleaner/ratings/jane-doe` as well as `/products/8426/ratings/72`. The controller action will be passed the parameter hash `{product_id: "vacuum-cleaner", id: "jane-doe"}` or `{product_id: "8426", id: "72"}`, respectively.

The `target` argument is a string with the controller name and the action name separated by the `#` character. For example, `'likes#show'` denotes the `show` action of the `LikesController`.

You can also equivalently specify the target via the `action` and `controller` properties of the  `options` hash.

The following properties of the `options` hash are recognized:

* **params** (Object): Constant parameters that will be added to the params passed to the action and overwrite any values coming from a named placeholder

    ```coffeescript
    match 'likes/:id', 'likes#show', params: {foo: 'bar'}
    ```

    ```javascript
    match('likes/:id', 'likes#show', {params: {foo: 'bar'}});
    ```

    In this example, the `LikesController` will receive a `params` hash which has a `foo` property.

* **constraints** (Object): For each placeholder you would like to put constraints on, pass a regular expression of the same name:

    ```coffeescript
    match 'likes/:id', 'likes#show', constraints: {id: /^\d+$/}
    ```

    ```javascript
    match('likes/:id', 'likes#show', {constraints: {id: /^\d+$/}});
    ```

    The `id` regular expression enforces the corresponding part of the path to be numeric. This route will match the path `/likes/5636`, but not `/likes/5636-icecream`.

    For every constraint in the constraints object, there must be a corresponding named placeholder, and it must satisfy the constraint in order for the route to match.
    For example, if you have a constraints object with three constraints: x, y, and z, then the route will match if and only if it has named parameters :x, :y, and :z and they all satisfy their respective regex.

* **name** (String): Named routes can be used when reverse-generating paths using `Chaplin.utils.reverse` helper:

    ```coffeescript
    match 'likes/:id', 'likes#show', name: 'like'
    Chaplin.utils.reverse 'like', id: 581  # => likes/581
    ```

    ```javascript
    match('likes/:id', 'likes#show', {name: 'like'});
    Chaplin.utils.reverse('like', {id: 581});  // => likes/581
    ```
    If no name is provided, the entry will automatically be named by the scheme `controller#action`, e.g. `likes#show`.

<h3 class="module-member" id="route">route([path])</h3>

Route a given path manually. Returns a boolean after it has been matched against the registered routes, corresponding to whether or not a match occurred. Updates the URL in the browser.

* **path** can be an object describing a route by
  * **controller**: name of the controller,
  * **action**: name of the action,
  * **name**: name of a [named route](#match), can replace **controller** and **action**,
  * **params**: params hash.

For routing from other modules, `Chaplin.utils.redirectTo` can be used. All of the following would be valid use cases.

```coffeescript
Chaplin.utils.redirectTo 'messages#show', id: 80
Chaplin.utils.redirectTo controller: 'messages', action: 'show', params: {id: 80}
Chaplin.utils.redirectTo url: '/messages/80'
```
```javascript
Chaplin.utils.redirectTo('messages#show', {id: 80});
Chaplin.utils.redirectTo({controller: 'messages', action: 'show', params: {id: 80}});
Chaplin.utils.redirectTo({url: '/messages/80'});
```

<h3 class="module-member" id="changeURL">changeURL([url])</h3>

Changes the current URL and adds a history entry without triggering any route actions.

Handler for the globalized `router:changeURL` request-response handler.

* **url**: string that is going to be pushed as the page’s URL

<h3 class="module-member" id="dispose">dispose()</h3>

Stops the Backbone.history instance and removes it from the router object. Also unsubscribes any events attached to the Router. On compliant runtimes, the router object is frozen, see [Object.freeze](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Object/freeze).

## Request-response handlers of `Chaplin.Router`

`Chaplin.Router` sets these global request-response:

* `router:route path[, options]`
* `router:reverse name, params[, options], callback`
* `router:changeURL url[, options]`

## Usage
`Chaplin.Router` is a dependency of [Chaplin.Application](./chaplin.application.html) which should be extended by your main application class. Within your application class you should initialize the `Router` by calling `initRouter` (passing your routes module as an argument) followed by `start`.


```coffeescript
define [
  'chaplin',
  'routes'
], (Chaplin, routes) ->
  'use strict'

  class MyApplication extends Chaplin.Application
    title: 'The title for your application'

    initialize: ->
      super
      @initRouter routes
      @start()
```

```javascript
define([
  'chaplin',
  'routes'
], function(Chaplin, routes) {
  'use strict';

  var MyApplication = Chaplin.Application.extend({
    title: 'The title for your application',

    initialize: function() {
      Chaplin.Application.prototype.initialize.apply(this, arguments);
      this.initRouter(routes);
      this.start();
    }
  });

  return MyApplication;
});
```
