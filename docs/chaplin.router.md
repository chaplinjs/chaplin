# Chaplin.Router
The `Router` is responsible for observing URL changes. If a declared route matches the current URL, a `matchRoute` event is triggered.

The Chaplin `Router` is a replacement for [Backbone.Router](http://documentcloud.github.com/backbone/#Router) and does not inherit from Backbone’s `Router`. It’s a different implementation with several advantages over the standard router.

In Backbone there are no controllers. Backbone’s `Router` maps routes to its *own methods*, so it’s serves two purposes. The Chaplin `Router` is just a router, it maps URLs to *separate controllers*, in particular *controller actions*. Just like Backbone’s standard router, Chaplin is using `Backbone.History` in the background. That is, Chaplin relies upon Backbone for Hash URLs and HTML5 History (`pushState`/`popstate`).

## Declaring Routes in the `routes` file

By convention, all application routes should be declared in a separate file, the `routes` module. This is a simple JavaScript module which calls the `match` method of the `Router` several times. For example:

```coffeescript
match '', 'home#index'
match 'likes/:id', controller: 'controllers/likes', action: 'show'
```

`match` works much like the Ruby on Rails counterpart. If a route matches, a `matchRoute` event is published passing the route instance and a `params` hash which contains pattern matches (like `id` in the example above) and additional GET parameters.

## Methods of `Chaplin.Router`

<a name="createHistory"></a>

### createHistory

Creates the `Backbone.History` instance


<a name="startHistory"></a>

### startHistory

Starts the `Backbone.History` instance.  This method should be called after all the routes have been registered.


<a name="stopHistory"></a>

### stopHistory

Stops the `Backbone.History` instance from observing URL changes.


<a name="match"></a>

### match( [pattern], [target], [options={}] )

Connects an address with a controller action.  Creates a new Route instance and registers it on the current Backbone.History instance.

* **pattern** (String): A pattern to match against the current URL
* **target** (String): the controller action which is called when the route matches
* **options** (Object): optional object to be passed to the Routes object

The `pattern` argument may contain named placeholders starting with a <code>:</code> (colon) followed by an identifier. For example, <code>'products/:product_id/ratings/:id'</code> will match the URLs
<code>/products/vacuum-cleaner/ratings/jane-doe</code> as well as <code>/products/8426/ratings/72</code>. The controller action will be passed a parameter hash with `product_id: 'vacuum-cleaner', id: 'jane-doe'` and `product_id: '8426', id: '72'`, respectively.

The `target` argument is a string with the controller name and the action name separated by the <code>#</code> character. For example, `'likes#show'` denotes the `LikesController` and its `show` action.

In the third parameter, fixed parameters may be passed. They will be added to the `params` hash which will be passed to the controller action. They cannot be overwritten by parameters from the URL. For example:

```coffeescript
match 'likes/:id', 'likes#show', params: { foo: 'bar' }
```

In this example, the `LikesController` will receive a `params` hash which has a `foo` property.

Additionally, the third parameter may impose additional constraints on named placeholders. Pass an object in the `constraints` property. Add a property for each placeholder you would like to put constraints on. Pass a regular expression as the value. For example:

```coffeescript
match 'likes/:id', 'likes#show', constraints: { id: /^\d+$/ }
```

The regular expression if the ID consists of digits only. This route will match the URL `/likes/5636`



<a name="route"></a>

### route( [path] )

Route a given path manually. Returns a boolean after it has been matched against the registered routes.

This looks quite like `Backbone.history.loadUrl`, but it accepts an absolute URL with a leading slash (e.g. `/foo`) and passes a `changeURL` parameter to the route handler function.

* **path**: an absolute URL with a leading slash


<a name="routeHandler"></a>

### routeHandler( [path], [callback] )

Listener for global `!router:route` event. Tries to match the given URL against Call the callback associated with the route.
When the

<ul class="arguments">
  <li>
* **path**: an absolute URL with a leading slash
  </li>
  <li>
* **callback**: a callback which is called in any case after routing.
  </li>
</ul>


<a name="changeURL"></a>

### changeURL( [url] )

Changes the current URL and adds a history entry.  Does not trigger any routes.

* **url**: string that is going to be pushed as the pages url


<a name="changeURLHandler"></a>

### changeURLHandler( [url] )

Handler for the globalized `!router:changeURL` event.  Calls `@changeURL`.

* **url**: string that is going to be pushed as the pages url


<a name="dispose"></a>

### dispose

Stops the Backbone.history instance and removes it from the Router object.  Also unsubscribes any events attached to the Router.  Attempts to freeze the Router to prevent any changes to the Router. See [Object.freeze](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Object/freeze).

## Usage
The Chaplin Router is a dependancy of [Chaplin.Application](./chaplin.application.md) which should be extended from by your main application class. Within your application class you should initialize the Router by calling `@initRouter` passing your routes module as an argument.

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
```

## [Code](https://github.com/chaplinjs/chaplin/blob/master/src/chaplin/lib/router.coffee)
