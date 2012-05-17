![Chaplin](http://s3.amazonaws.com/imgly_production/3401027/original.png)

# An Application Architecture Using Backbone.js

## Introduction

Chaplin is an architecture for JavaScript applications using the [Backbone.js](http://documentcloud.github.com/backbone/) library. The code is derived from [moviepilot.com](http://moviepilot.com/), a large single-page application.

* [Current Version: 0.4](#current-version)
* [Upcoming Version: Chaplin as a Library](#upcoming-version-chaplin-as-a-library)
* [Stay Tuned for Updates](#stay-tuned-for-updates)
* [Key Features](#key-features)
* [Motivation](#motivation)
* [Dependencies](#dependencies)
* [Building Chaplin](#building-chaplin)
* [Boilerplate and Examples](#boilerplate-and-examples)
* [The Architecture in Detail](#the-architecture-in-detail)
* [Application](#application)
* [Mediator and Publish/Subscribe](#mediator-and-publishsubscribe)
* [Router](#router)
* [Dispatcher](#dispatcher)
* [Layout](#layout)
* [Controllers](#controllers)
* [Models and Collections](#models-and-collections)
* [Views](#views)
* [Event Handling Overview](#event-handling-overview)
* [Memory Management and Object Disposal](#memory-management-and-object-disposal)
* [Handling Asynchronous Dependencies](#handling-asynchronous-dependencies)
* [The Cast](https://github.com/chaplinjs/chaplin/blob/master/AUTHORS.md#toc-cast)
* [The Producers](https://github.com/chaplinjs/chaplin/blob/master/AUTHORS.md#toc-producers)

## Current Version

The current stable version is **0.3**, released on 2012-03-23.

To use the stable version, please clone the repository and [check out the tag 0.3](https://github.com/chaplinjs/chaplin/tree/0.3).

See also the [Changelog](https://github.com/chaplinjs/chaplin/blob/master/CHANGELOG.md).

## Upcoming Version: Chaplin as a Library

While the stable version is merely an example application structure, our goal is to generalize Chaplin into a separate, reusable and unit-tested library.

There’s a major rewrite going on and the `master` branch already reflects these changes. We’re working on several topics:

- Improving and generalizing the Chaplin architecture
- Writing tests for all Chaplin core components
- Writing an up-to-date documentation and writing a class & method reference
- Creating a boilerplate app, outsourcing the current application examples

How about joining us? You might also have a look at the [issue discussions](https://github.com/chaplinjs/chaplin/issues) about changes on the structure. There is also a [mailing list for discussion on Google Groups](https://groups.google.com/forum/?hl=en&fromgroups#!forum/chaplin-js
).

## Stay tuned for updates

[Follow Chaplin.js on Twitter](https://twitter.com/chaplinjs) to get updates on new versions, major changes and the ongoing development.

---

## Key Features

* CoffeeScript class hierarchies as well as object composition
* Module encapsulation and lazy-loading using AMD modules
* Cross-module communication using the Mediator and Publish/Subscribe patterns
* Controllers for managing individual UI views
* Rails-style routes which map URLs to controller actions
* A route dispatcher and a top-level view manager
* Extended model, view and collection classes to avoid repetition and enforce conventions
* Strict memory management and object disposal
* A collection view for easy and intelligent list rendering

## Motivation

![Modern Times](http://s3.amazonaws.com/imgly_production/3359809/original.jpg)

While developing several web applications using Backbone.js, we felt the need for conventions on how to structure such applications. While Backbone is fine at what it’s doing, it’s not a [framework](http://stackoverflow.com/questions/148747/what-is-the-difference-between-a-framework-and-a-library) for single-page applications. Yet it’s often used for this purpose.

Chaplin is mostly derived and generalized from the codebase of [moviepilot.com](http://moviepilot.com/), a real-world single-page application. Chaplin tries to draw the attention to top-level application architecture. “Application” means everything above simple routing, individual models, views and their binding.

Backbone is an easy starting point, but provides only basic, low-level patterns. Especially, Backbone provides little to structure an actual application. For example, the famous “Todo list example” is not an application in the strict sense nor does it teach best practices how to structure Backbone code. 

To be fair, Backbone doesn’t intend to be an all-round framework so it wouldn’t be appropriate to blame Backbone for this deliberate limitations. Nonetheless, most Backbone use cases clearly need a sophisticated application architecture. This is where Chaplin enters the stage.

## Dependencies

Chaplin depends on the following libraries:

* [Underscore](http://documentcloud.github.com/underscore/)
* [Backbone](http://documentcloud.github.com/backbone/)
* [jQuery](http://jquery.com/)
* An AMD module loader like [RequireJS](http://requirejs.org/), [Almond](https://github.com/jrburke/almond) or [curl](https://github.com/cujojs/curl) to load Chaplin and lazy-module application modules

## Building Chaplin

The individual source files of Chaplin are originally written in the [CoffeeScript](http://coffeescript.org/) meta-language. The Chaplin library file however is compiled JavaScript file which defines the `chaplin` AMD module.

To compile the CoffeeScripts and bundle them into one file, please run the Ruby script `build.rb` in the `build` directory:

```
cd build
./build.rb
```

This creates several files in ./build/:

* `chaplin.coffee` – The Chaplin library in one CoffeeScript file
* `chaplin.js` – The same as a compiled JavaScript file
* `chaplin-min.js` – Minified
* `chaplin-min.js.gz` – Minified and GZip-compressed

## Boilerplate and Examples

In separate repositories, you will find a example applications which can also be used as a boilerplate:

### Facebook Like Browser

[github.com/chaplinjs/facebook-example](https://github.com/chaplinjs/facebook-example)

This example uses Facebook client-side authentication to display the user’s Likes.

### Twitter Client

[github.com/brunch/twitter](https://github.com/brunch/twitter)

This example uses Twitter client-side authentication to display user’s feed and to create new tweets. It uses [brunch](http://brunch.io) for assembling files & assets.

## The Architecture in Detail

The following chapters will discuss the core objects and classes of our application structure.

![Machine](http://img.ly/system/uploads/003/362/032/original_machine.jpg)

## Application

The root object of the JavaScript application is just called `Application`. In practise, you might choose a more meaningful name. `Application` is merely a bootstrapper which starts up three other core modules:


* `mediator`
* `Router`
* `Dispatcher`
* `Layout`


## Mediator and Publish/Subscribe

Using the AMD module convention, a script might load other objects it depends upon, like the class (constructor) it inherits from. Since most objects are encapsulated and not publicly accessible, a module normally does not have access to the actual instances of other classes.

Modules communicate and share data using the `mediator`. That’s just a simple object which has per default three methods for global Publish/Subscribe: `subscribe`, `unsubscribe` and `publish`.

[Publish/Subscribe](http://en.wikipedia.org/wiki/Publish/subscribe) (Pub/Sub) is a versatile pattern to ensure loose coupling of application modules. To inform other modules that something happened, a module doesn’t send messages directly (i.e. calling methods of specific objects). Instead, it publishes a message to a central channel without having to know who is listening. Other application modules might subscribe to these messages and react upon them.

For simplicity, we borrow the functionality from the `Backbone.Events` mixin. The `subscribe`, `unsubscribe` and `publish` methods are simply aliases for `trigger`, `on` and `off` of the `Backbone.Events` mixin.

For example, several modules are interested in the user login event and subscribe to the `login` message. In practice, they load `chaplin` as a dependency and register a callback function for the `login` event:

```
Chaplin.mediator.subscribe 'login', @doSomething
```

A Publish/Subscribe message consists of a name and optional data. For example, the module in charge of handling the login might publish a message with the identifer `login` and the `user` object as additional data:

```
# Publish a global login event
mediator.publish 'login', user
```

The second and all subsequent arguments are passed through to the handler functions.

## Router

The Router is responsible for observing URL changes. If a declared route matches the current URL, an event is triggered.

The Chaplin `Router` does not inherit from Backbone’s `Router`. It’s a different implementation with several advantages over the standard router.

In Backbone’s concept, there are no controllers. Backbone’s `Router` maps routes to its <em>own methods</em>, so it’s serves two purposes. Our `Router` is just a router, it maps URLs to <em>separate controllers</em>, in particular <em>controller actions</em>. Just like Backbone’s standard router, we’re using an instance of `Backbone.History` in the background.

By convention, all application routes should be declared in a separate file, the `routes` module. The Chaplin `Router` has a `match` method to create routes which is used to register routes:.

```
match 'likes/:id', 'likes#show'
```

`match` works much like the Ruby on Rails counterpart since it creates a proper `params` hash. If a route matches, a `matchRoute` event is published passing the route instance and the parameter hash.

Additional fixed parameters and parameter constraints may be specified in the `match` call:

```
match 'likes/:id', 'likes#show', constraints: { id: /^\d+$/ }, params: { foo: 'bar' }
```

## Dispatcher

Between the router and the controllers, there is the `Dispatcher` which listens for routing events. On such events, it loads the target controller module, creates a controller instance and calls the target action. The previously active controller is automatically disposed.

A specific controller may also be started programatically. To start a specific controller, an app-wide `!startupController` event can be published:

```
mediator.publish '!startupController', 'controller', 'action', params
```

The `Dispatcher` handles the `!startupController` event.

## Layout

The Layout is the top-level application view. When a new controller was activated, the `Layout` is responsible for changing the main view to the view of the new controller.

In addition, the `Layout` handles the activation of internal links. That is, you can use a normal `<a href="/foo">` element to link to another application module.

## Controllers

In the Chaplin concept, a controller is the place where a model and associated views are instantiated. A controller is also in charge of model and view disposal when another controller takes over. Typically, a controller represents a screen of the application.

There can be one current controller which provides the main view and represents the current URL. In addition, there can be several persistent controllers which govern special views like a header, a navigation sidebar or a footer.

### Specific Module Controllers

By convention, there is a controller for each application module. A controller may provide several action methods like `index`, `show`, `edit` and so on. These actions are called by the `Dispatcher` when a route matches.

For example, this is the stripped-down `LikesController`:

```
define ['controllers/controller', 'models/likes', 'models/like', 'views/likes_view', »»
  'views/full_like_view'], (Controller, Likes, Like, LikesView, FullLikeView) ->

  'use strict'

  class LikesController extends Controller

    historyURL: (params) ->
      if params.id then "likes/#{params.id}" else ''

    # initialize method is empty here

    index: (params) ->
      @collection = new Likes()
      @view = new LikesView collection: @collection

    show: (params) ->
      @model = new Like id: params.id
      @view = new FullLikeView model: @model
```

A typical controller has one model or collection and one associated view. They should be stored in the `model`/`collection` and `view` instance properties so they are disposed automatically on controller disposal.

Per default, a controller is instantiated afresh with every route match. That means models and views are disposed by default even if the new controller is the same as the old controller. To persist models and views, it is recommended to save them in a central store, not on the controller instances.

Most of the time, a controller is started following a route match. In this case, the URL representing the application state is already given. But a controller can also be started programatically by publishing a `!startupController` event. In this case, the URL has to be determined. This is the purpose of the `historyURL` method.

## Models and Collections

Chaplin extends the standard Backbone models and collections with some new methods. `dispose` is the destructor for cleaning up. The Chaplin `Collection` also has `addAtomic` for adding several items while fireing a `reset` event, and `update` for updating a collection while fireing several `add`/`remove` events instead of a single `reset` event.

Using these `Model` and `Collection` classes, we create a hierarchy of CoffeeScript classes. Many child classes override methods while calling `super`.

Models and collections are Publish/Subscribe event subscribers by using the `Subscriber` mixin. Please do not register their methods directly as Pub/Sub listeners, use `subscribeEvent` instead. This forces the handler context so the handler might be removed again on model/collection disposal. It’s crucial to remove all references to model/collection methods to allow them to be garbage collected.

## Views

Chaplin’s `View` class is a highly extended and adapted Backbone `View`. All views should inherit from this class to avoid repetition.

Views may subscribe to Publish/Subscribe and model/collection events in a manner which allows proper disposal. They have a standard `render` method which renders a template into the view’s root element (`@el`).

The templating function is provided by `getTemplateFunction`. The input data for the template is provided by `getTemplateData`. By default, this method just returns an object which delegates to the model attributes. Views might override the method to process the raw model data for the view.

In addition to Backbone’s `events` hash and the `delegateEvents` method, Chaplin has the `delegate` method to register user input handlers. The declarative `events` hash doesn’t work well for class hierarchies when several `initialize` methods register their own handlers. The programatic approach of `delegate` solves these problems.

Also, `@model.bind()` should not be used directly. Chaplin has `@modelBind()` which forces the handler context so the handler can be removed automatically on view disposal. When using Backbone’s naked `bind`, you have to deregister the handler manually to clear the reference from the model to the view.

### CollectionView

The `CollectionView` is responsible for displaying collections. For every item in a collection, it instantiates a given item view and inserts it into the DOM. It reacts to collection change events (`add`, `remove` and `reset`) and provides basic filtering, caching of views, fallback content and loading indicators.

## Event Handling Overview

![Dance](http://s3.amazonaws.com/imgly_production/3362020/original.jpg)

For models and views, there are several wrapper methods for event handler registration. In contrast to the direct methods they will save memory because the handlers will be removed correctly once the model or view is disposed.

### Global Publish/Subscribe Events

In models and views, there is a shortcut for subscribing to global events:

```
@subscribeEvent 'login', @doSomething
```

This method has the advantage of removing the subscription on model or view disposal.

The `subscribeEvent` method has a counterpart `unsubscribeEvent`. These mehods are defined in the `Subscriber` mixin, which also provides the `unsubscribeAllEvents` method.

### Model Events

In views, the standard `@model.bind` way to register a handler for a model event should not be used. Use the memory-saving wrapper `modelBind` instead:

```
@modelBind 'add', @doSomething
```

In a model, it’s fine to use `bind` directly as long as the handler is a method of the model itself.

A view also provides `modelUnbind` and `modelUnbindAll` for deregistering. The latter is called automatically on view disposal.

```
@modelUnbind 'add', @doSomething
```

### User Input Events

Most views handle user input by listening to DOM events. Backbone provides the `events` property to register event handlers declaratively. But this does not work nicely when views inherit from each other and a specific view needs to handle additional events.

Chaplin’s `View` class provides the `delegate` method as a shortcut for `@$el.on`. It has the same signature as the jQuery 1.7 `on` method. Some examples:

```
@delegate 'click', '.like-button', @like
@delegate 'click', '.close-button', @skip
```

`delegate` registers the handler at the topmost DOM element of the view (`@el`) and catches events from nested elements using event bubbling. You can specify an optional selector to target nested elements.

In addition, `delegate` automatically binds the handler to the view object, so `@`/`this` points to the view. This means `delegate` creates a wrapper function which acts as the handler. As a consequence, it’s currently not possible to unbind a specific handler. Please use `@$el.off` directly to unbind all handlers for an event type for a selector:

```
@$el.off 'click', '.like-button'
@$el.off 'click', '.close'
```

## Memory Management and Object Disposal

One of the core concerns of the Chaplin architecture is a proper memory management. There isn’t a broad discussion about garbage collection in JavaScript applications, but in fact it’s an important topic. Backbone provides little out of the box so Chaplin ensures that every controller, model, collection and view cleans up after itself.

Event handling creates references between objects. If a view listens for model changes, the model has a reference to a view method in its internal `_callbacks` list. View methods are often bound to the view instance using `Function.prototype.bind`, `_.bind()`, CoffeeScript’s fat arrow `=>` or alike. When a `change` handler is bound to the view, the view will remain in memory even if it was already detached from the DOM. The garbage collector can’t free its memory because of this reference.

Before a new controller takes over and the user interface changes, the `dispose` method of the current controller is invoked. The controller calls `dispose` on its models/collections and then removes references to them. On disposal, a model clears all its attributes and disposes all associated views. A view removes all DOM elements and unsubscribes from DOM or model/collection events. Models/collections and views unsubscribe from global Publish/Subscribe events.

This disposal process is quite complex and many objects needs a custom `dispose` method. But this is just the least Chaplin can do.

## Handling Asynchronous Dependencies

Most processes in a client-side JavaScript application run asynchronously. It is quite common that an applications is communicating with different external APIs. API bridges are established on demand and of course all API calls are asynchronous. Lazy-loading code and content is a key to perfomance. Therefore, handling asynchronous dependencies is a big challenges for JavaScript web applications. We’re using the following techniques to handle dependencies, from bottom-level to top-level.

### Backbone Events

Of course, model-view-binding, Backbone’s key feature, is still a building block in Chaplin: A view can listen to model changes by subscribing to `change` event or other custom model events. In addition, collection and collection views are able to listen for events which occur on their items. This works because model events bubble up to the collection.

### State Machines for Synchronization: Deferreds and SyncMachine

Models, collections and third-party scripts typically have a loaded state. At the beginning, they aren’t ready to use. The data is fetched from the server, they need to wait for the user login or rely upon other asynchronous input.

For these purpose, [jQuery Deferreds](http://api.jquery.com/category/deferred-object/) can be mixed into appliation objects. They allow to register load handlers using the [done](http://api.jquery.com/deferred.done/) method. The handlers will be called once the Deferred is resolved.

Deferreds are a versatile pattern which can be used on different levels in an application, but they are rather simple because they only have three states (pending, resolved, rejected) and two transitions (resolve, reject). For more complex synchronization tasks, Chaplin offers the `SyncMachine` which is a state machine 

### Wrapping Methods to Wait for a Deferred

On moviepilot.com, methods of several Deferreds are called everywhere throughout the application. It would not be feasible for every caller to check the resolved state and register a callback if necessary. Instead, these methods are wrapped so they can be called safely before the Deferred is resolved. In this case, the calls are automatically saved as `done` callbacks, from later on they are passed through immediately. Of course this wrapping is only possible for asynchronous methods which don’t have a return value but expect a callback function.

The helper method `utils.deferMethods` in [the Facebook example repository](https://github.com/chaplinjs/facebook-example/blob/master/coffee/lib/utils.coffee) wraps methods so calls are postponed until a given Deferred object is resolved. The method is quite flexible and we’re using it in several situations.

### Publish/Subscribe

The Publish/Subscribe pattern is the most important glue in Chaplin applications because it’s used for most of the cross-module interaction. It’s a powerful pattern to promote loose coupling of application modules. Chaplin’s implementation using `Backbone.Events` is simply but highly beneficial.

![Ending](http://s3.amazonaws.com/imgly_production/3362023/original.jpg)

## [The Cast](https://github.com/chaplinjs/chaplin/blob/master/AUTHORS.md#toc-cast)

## [The Producers](https://github.com/chaplinjs/chaplin/blob/master/AUTHORS.md#toc-producers)
