![Chaplin](http://s3.amazonaws.com/imgly_production/3401027/original.png)

# A Sample Application Architecture Using Backbone.js

## Introduction

Chaplin is an example architecture for JavaScript applications using the [Backbone.js](http://documentcloud.github.com/backbone/) library. The code is derived from [moviepilot.com](http://moviepilot.com/), a large single-page application.

* [Key Features](#toc-key-featurs)
* [Motivation](#toc-motivation)
* [Technology Stack](#toc-technology-stack)
* [The Example Application](#toc-example-application)
* [The Architecture in Detail](#toc-architecture-in-detail)
* [Application](#toc-application)
* [Mediator and Publish/Subscribe](#toc-mediator-and-pub-sub)
* [Router and Route](#toc-router-and-route)
* [The Controllers](#toc-controllers)
* [Models and Collections](#toc-models-and-collections)
* [Views](#toc-views)
* [Fat Models and Views](#toc-fat-models-and-views)
* [Event Handling Overview](#toc-event-handling)
* [Memory Management and Object Disposal](#toc-memory-management)
* [Application Glue and Dependency Management](#toc-application-glue)
* [Conclusions](#toc-conclusions)
* [The Cast](#toc-cast)
* [The Producers](#toc-producers)

## <a name="toc-key-features">Key Features</a>

* CoffeeScript class hierarchies as well as object composition
* Module encapsulation and lazy-loading using RequireJS
* Cross-module communication using the Mediator and Publish/Subscribe patterns
* Controllers for managing individual UI views
* Rails-style routes which map URLs to controller actions
* An application view as dispatcher and view manager
* Extended model, view and collection classes to avoid repetition and enforce conventions
* Strict memory management and object disposal
* A collection with additional manipulation methods for smarter change events
* A collection view for easy and intelligent list rendering
* Client-side authentication using service providers like Facebook, Google and Twitter

## <a name="toc-motivation">Motivation</a>

![Modern Times](http://s3.amazonaws.com/imgly_production/3359809/original.jpg)

While developing web applications like [moviepilot.com](http://moviepilot.com/) and [salon.io](http://salon.io/), we felt the need for conventions on how to structure Backbone applications. While Backbone is fine at what it’s doing, it’s not a [framework](http://stackoverflow.com/questions/148747/what-is-the-difference-between-a-framework-and-a-library) for single-page applications. Yet it’s often used for this purpose.

To promote the discussion on JavaScript applications, we decided to open-source and document our application architecture. Chaplin is mostly derived and generalized from the moviepilot.com codebase.

Chaplin does not intend to provide an all-purpose, ready-to-use library. It’s an example how a real-world application structure might look like. Consider it as a scaffold which needs to be adapted to the needs of a specific application.

This repository is a snapshot of our ongoing efforts. We’re evolving the structure of moviepilot.com over the time and we’re using Chaplin as a testbed and playground. Of course this architecture is not flawless. In fact there are several open issues so your feedback is appreciated!

## <a name="toc-technology-stack">Technology Stack</a>

For simplicity reasons, Chaplin consists of plain HTML, CSS and JavaScript. However, the JavaScripts are originally written in the [CoffeeScript](http://coffeescript.org/) meta-language. Most `.coffee` files contain CoffeeScript “class” declarations. In this repository, you will find _both_ the original CoffeeScripts and the compiled JavaScripts. So there is no need to compile the CoffeeScripts in order to start the demo.

If you would like to modify the CoffeeScripts, you can translate them JavaScript using the CoffeeScript compiler. After installing CoffeeScript, you might run this command:

```
coffee --bare --output js/ coffee/
```

The example application uses the following JavaScript libraries:

* [RequireJS](http://requirejs.org/) for lazy-loading of scripts and dependency management,
* [jQuery](http://jquery.com/) for DOM scripting and Ajax,
* [Underscore](http://documentcloud.github.com/underscore/) as a data processing and functional helper,
* [Backbone](http://documentcloud.github.com/backbone/) for models, views, routing and history management,
* [Handlebars](http://handlebarsjs.com/) for view templates.

We’re using RequireJS to define AMD modules and load JavaScript files automatically. However, the mentioned core libraries are not loaded using RequireJS, they are loaded with normal `script` elements synchronously. You might want to [wrap](https://github.com/geddesign/wrap.js) jQuery, Backbone, Underscore and Handlebars as RequireJS modules to get the full AMD experience.

In our real-world applications, we’re using several tools for compiling and packaging scripts, stylesheets and templates. On moviepilot.com, we’re using the [Ruby on Rails 3.2 asset pipeline](http://guides.rubyonrails.org/asset_pipeline.html) together with Node.js to compile CoffeeScripts, Sass/Compass stylesheets as well as Handlebars templates on the server. On salon.io, we’re using [Brunch](http://brunch.io/) which is based on Node.js.

Since this example isn’t about building and deployment, it has no such dependencies. Nevertheless RequireJS allows to [pre-build a package](http://requirejs.org/docs/optimization.html) with the initial modules. You might build a bootstrap package by running this command in the `/js` directory:

```
r.js -o name=application out=built.js paths.text=vendor/require-text-1.0.6 baseUrl=.
```

## <a name="toc-example-application">The Example Application: Facebook Likes Browser</a>

While traditional site login using e-mail and password is still around, single sign-on gained popularity. The example application features a client-side OAuth 2.0 login with [Facebook Connect](https://developers.facebook.com/docs/reference/javascript/FB.login/). Facebook is just a sample service provider. On moviepilot.com, we’re also using the [Google APIs Client Library](http://code.google.com/p/google-api-javascript-client/). We have experimented with [Twitter Anywhere](https://dev.twitter.com/docs/anywhere/welcome) which provides a client-side login but doesn’t support OAuth 2.0. (Moviepilot.com allows you to log in with Twitter, but it’s an old-school OAuth 1.0 server-side login.)

This example uses a Facebook application named “Chaplin Example App”. On login, you will be asked to grant access rights to this Facebook app. Of course this app will not post anything to Facebook on your behalf or publish/submit your personal data. You’re free to [revoke access rights](https://www.facebook.com/settings/?tab=applications) at any time. You might easily [create your own Facebook App](https://developers.facebook.com/apps) and change the app ID in `facebook.coffee`/`facebook.js`.

The Facebook login only works if the app runs on the (nonexistent) domain `chaplin.moviepilot.com`. To access the application, follow these steps:

* Add a line like `127.0.0.1   chaplin.moviepilot.com` to your [hosts file](http://en.wikipedia.org/wiki/Hosts_(file)).
* Start a simple local HTTP server (like nginx for example), point the document root to the app folder.
* Then you’re able to access *http://chaplin.moviepilot.com/* in your browser and log in with Facebook.

After successful login, your Facebook likes are fetched from the Open Graph and displayed as a list. You might click a list entry to see more details.

Besides the likes browsers, there’s a second screen which displays some latest posts on the moviepilot.com Facebook page. This is just another controller in order to demonstrate the change between controllers with proper routing and cleanup.

## <a name="toc-architecture-in-detail">The Architecture in Detail</a>

The following chapters will discuss the core objects and classes of our application structure.

![Machine](http://img.ly/system/uploads/003/362/032/original_machine.jpg)

## <a name="toc-application">Application</a>

The root object of the JavaScript application is just called `Application`. In practise, you might choose a more meaningful name. `Application` is merely a bootstrapper which starts up three other core modules:


* `SessionController`
* `ApplicationController`
* `Router`


## <a name="toc-mediator-and-pub-sub">Mediator and Publish/Subscribe</a>

In this sample application we’re using RequireJS to load JavaScript files on demand. While a script might load another object it depends upon or a class (constructor) it inherits from, it normally does not have access to the actual instances. Most objects are encapsulated and not publicly accessible.

Modules communicate and share data using the `mediator`. That’s just a simple object with some properties:

* `user`– If there’s a logged-in user, the user object. `null` if not logged in.
* `router` – The router which maps URLs to controllers.
* `subscribe`, `unsubscribe`, `publish` – Methods for global Publish/Subscribe

[Publish/Subscribe](http://en.wikipedia.org/wiki/Publish/subscribe) (Pub/Sub) is a versatile pattern to ensure loose coupling of application modules. To inform other modules that something happened, a module doesn’t send messages directly (i.e. calling methods of specific objects). Instead, it publishes a message to a central channel without having to know who is listening. Other application modules might subscribe to these messages and react upon them.

For simplicity, we borrow the functionality from the `Backbone.Events` mixin. The `subscribe`, `unsubscribe` and `publish` methods are simply aliases for `trigger`, `bind` and `unbind` of the `Backbone.Events` mixin.

For example, several modules are interested in the user login event and subscribe to the `login` message. In practice, they load `mediator` as a dependency and register a callback function for the `login` event:

```
mediator.subscribe 'login', @doSomething
```

A Publish/Subscribe message consists of a name and optional data. The `SessionController` is in charge for the user login, so it publishes a message with the identifer `login` and the `user` object as additional data:

```
# Publish a global login event
mediator.publish 'login', user
```

The second and all following arguments are passed as arguments to the handler functions.

## <a name="toc-router-and-route">Router and Route</a>

The `Router` in this example application does not inherit from Backbone’s `Router`. In fact it’s an implementation of its own with several advantages over the standard Backbone `Router`.

In Backbone’s concept, there are models and views, but no controllers. Backbone’s router maps routes to its <em>own methods</em>, so it’s serves two purposes. Our `Router` is just a router, it maps URLs to <em>separate controllers</em>, in particular controller actions. Just like Backbone’s standard router, we’re using an instance of `Backbone.History` in the background.

Our `Router` does not have a `route` method, but a `match` method to create routes:

```
@match 'likes/:id', 'likes#show'
```

`match` works much like the Ruby on Rails counterpart since it creates a proper `params` hash. If a route matches, the corresponding `Route` object publishes a `matchRoute` event passing the route instance and the parameter hash.

Additional fixed parameters and parameter constraints may be specified in the `match` call:

```
@match 'likes/:id', 'likes#show', constraints: { id: /^\d+$/ }, params: { foo: 'bar' }
```

## <a name="toc-controllers">The Controllers</a>

In our concept, a controller is the place where a model and associated views are instantiated. A controller is also in charge of model and view disposal once another controller takes over. Typically, a controller represents a screen of the application. There can be one current controller.

There may be plenty of controllers for specific replaceable application modules, but few persistent meta-controllers with special views.

### ApplicationController

The application controller instantiates common models/collections and views which are active the whole time (header, sidebars, footer and so on). Most importantly, it instantiates the `ApplicationView`.

### ApplicationView

Between the router and the controllers, there’s the `ApplicationView` as a dispatcher. It allows switching between user interface modules by starting up specific controllers. To show a specific module, an app-wide `!startupController` event is published:

```
mediator.publish '!startupController', 'controllerName', 'controllerAction', optionalParams
```

The `ApplicationView` handles the `!startupController` event. It creates a controller instance, calls the controller action and may perform a transition from the current to the new controller.

In addition, the `ApplicationView` changes the interface chrome on application-wide events like `login` and `logout`. It also handles the activation of application-internal links. That is, you just have to use a normal `<a href="/foo">` element to link to another application module.

### Specific Module Controllers

By convention, there is a controller for each application module. A controller may provide several action methods like `index`, `show` and so on. These actions are called by `ApplicationView` when a route matches. In addition to specific actions, a controller might provide a `initialize` method which is called before a specific action.

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
      @model = new Like { id: params.id }, { loadDetails: true }
      @view = new FullLikeView model: @model
```

A typical controller has one model or collection and one associated view. They should be stored in the `model`/`collection` and `view` instance properties so they are disposed automatically on controller disposal.

## <a name="toc-models-and-collections">Models and Collections</a>

We extended the standard Backbone models and collections with some new methods. `dispose` is the destructor for cleaning up. Our `Collection` also has `addAtomic` for adding several items while fireing a `reset` event, and `update` for updating a collection while fireing several `add`/`remove` events instead of a single `reset` event.

Using these `Model` and `Collection` classes, we create a hierarchy of CoffeeScript classes. Many child classes override methods while calling `super`.

Models and collections are Publish/Subscribe event subscribers by using the `Subscriber` mixin. We do not register their methods directly as listeners using `mediator.subscribe`. Instead, we use `subscribeEvent` which records the subscription so it might be removed again on model/collection disposal. It’s crucial to remove all external references to model/collection methods to allow them to be garbage collected.

## <a name="toc-views">Views</a>

Our `View` class is a highly extended and adapted Backbone `View`. All views inherit from this class to avoid repetition.

Views may subscribe to Publish/Subscribe and model/collection events in a manner which allows proper disposal. They have a standard `render` method which renders a Handlebars template into the view’s root element (`@el`). The input data for the template is provided by `getTemplateData`. By default, this method just returns an object which delegates to the model attributes. Views might override the method to process the raw model data for the view.

There are several differences to standard Backbone views:

We don’t use the `events` hash and the `delegateEvents` method to register user input handlers, but our own `delegate` method. The declarative hash approach doesn’t work well for class hierarchies when several `initialize` methods register their own handlers.

We don’t use `@model.bind()` directly. We have `@modelBind()` which records the subscription so the tie can be cut automatically on view disposal. When using Backbone’s naked `bind`, you have to deregister the handler manually to clear the reference from the model to the view.

### CollectionView

On moviepilot.com, `CollectionView` is one of the main workhorses. It’s responsible for displaying most of the collections. For every item in a collection, it instantiates a given item view and inserts it into the DOM. It reacts to collection change events (`add`, `remove` and `reset`) and provides basic filtering and caching of views.

The current `CollectionView` implementation is quite simple and could be improved in many ways, for example with regard to filtering, fallback content and loading indicators. Nevertheless the `CollectionView` is an essential piece. Rendering collections on the UI would be painful without it since Backbone does not provide a clean mechanism to render collections.

## <a name="toc-fat-models-and-views">Fat Models and Views</a>

Following Backbone’s design that models/collection can fetch themselves from the server or other stores, most of our fetching code is in the model/collection. On moviepilot.com, the actual API calls are located in separate modules, but the whole processing and updating logic resides in the model/collection. Model/collections may fetch themselves on initialization without receiving a call to do so.

Likewise, our views are quite independent. Most of them render themselves on instantiation, on model attribute change or on global events. They might event destroy themselves independently.

As a consequence, our controllers are quite skinny. In most cases, they just instantiate the model/collection an its associated view passing the necessary data. Then the model/collection and the view will handle the rest themselves.

There’s no specific reason for this decision, it’s merely a convention on where to put fetching and rendering code – your mileage may vary.

## <a name="toc-event-handling">Event Handling Overview</a>

![Dance](http://s3.amazonaws.com/imgly_production/3362020/original.jpg)

For models and views, there are several wrapper methods for event handler registration. In contrast to the direct methods they will save memory because the handlers will be removed correctly once the model or view is disposed.

### Global Publish/Subscribe Events

In models and views, there is a shortcut for subscribing to global events:

```
@subscribeEvent 'login', @doSomething
```

This method has the advantage of cancelling the subscription on model or view disposal.

The `subscribeEvent` method has a counterpart `unsubscribeEvent`. These mehods are defined in the `Subscriber` mixin, which also provides the `unsubscribeAllEvents` method.

### Model Events

In views, we don’t use the standard `@model.bind` method to register a handler for a model event. We use a memory-saving wrapper named `modelBind` instead.

```
@modelBind 'add', @doSomething
```

In a model, it’s fine to use `bind` directly as long as the handler is a method of the model itself.

A view also provides `modelUnbind` and `modelUnbindAll` for deregistering. The latter is called automatically on view disposal.

```
@modelUnbind 'add', @doSomething
```

### User Input Events

Most views handle user input by listening to DOM events. Backbone provides the `events` property to register event handlers declaratively. But this does not work nicely when views inherit from each other and a specific view needs to handle additional events. Therefore Backbone’s `events` object and `delegateEvents` aren’t used.

Our `View` class provides the `delegate` method as a shortcut for `@$el.on`. It has the same signature as the jQuery 1.7 `on` method. Some examples:

```
@delegate 'click', '.like-button', @like
@delegate 'click', '.close-button', @skip
```

`delegate` registers the handler at the topmost DOM element of the view (`@el`) and catches events from nested elements using event bubbling. You can specify an optional selector to target nested elements.

In addition, `delegate` automatically binds the handler to the view object, so `@`/`this` points to the view. This means `delegate` creates a wrapper function which acts as the handler. As a consequence, it’s currently not possible to unbind a specific handler. At the moment, we’re using `@$el.off` directly to unbind all handlers for an event type for a selector:

```
@$el.off 'click', '.like-button'
@$el.off 'click', '.close'
```

This isn’t the best solution but acceptable for now since this doesn’t occur frequently in our application.

## <a name="toc-memory-management">Memory Management and Object Disposal</a>

One of the core concerns of this architecture is a proper memory management. It seems there isn’t a broad discussion about garbage collection in JavaScript applications, but in fact it’s an important topic. Backbone provides little out of the box so we implemented it by hand: Every controller, model, collection and view cleans up after itself.

Event handling creates references between objects. If a view listens for model changes, the model has a reference to a view method in its `_callbacks` list. View methods are often bound to the view instance using `_.bind()`, CoffeeScript’s `=>` or such. When you register a `change` handler which is bound to the view, the view will remain in memory even if it was already detached from the DOM. The garbage collector can’t free their memory because of this reference.

Before a new controller takes over and the user interface changes, the `dispose` method of the current controller is invoked. The controller calls `dispose` on its models/collections and then removes references to them. On disposal, a model clears all its attributes and disposes all associated views. A view removes all DOM elements and unsubscribes from DOM or model/collection events. Models/collections and views unsubscribe from global Publish/Subscribe events.

This disposal process is quite complex and many objects needs a custom `dispose` method. But this is the least we could do. In Internet Explorer, moviepilot.com gets slow and memory consumption rises after several module changes despite all these efforts.

## <a name="toc-application-glue">Application Glue and Dependency Management</a>

Most processes in a client-side JavaScript application run asynchronously. It is quite common that an applications is communicating with different external APIs. API bridges are established on demand and of course all API calls are asynchronous. Lazy-loading code and content is a key to perfomance. Therefore, handling asynchronous dependencies was one of the biggest challenges for us. We’re using the following techniques to handle dependencies, from bottom-level to top-level.

### Backbone Events

Of course, model-view-binding, Backbone’s key feature, is still a building block in our structure. If you’re familiar with Backbone, you certainly know how to set up such a binding: A view can listen to model changes by subscribing to `change` event or other custom model events. In addition, collection and collection views are able to listen for events which occur on their items. This works because model events bubble up to the collection.

### jQuery Deferreds

Many objects like models, collections and APIs have a loaded state. At the beginning, they aren’t ready to use. They have to wait for the user login or other asynchronous I/O. These objects are [jQuery Deferreds](http://api.jquery.com/category/deferred-object/). You can register load callbacks using the [done](http://api.jquery.com/deferred.done/) method. They will be processed when the Deferred is resolved.

Deferreds are a versatile pattern which can be used on different levels in an application. Deferreds can also be chained using [jQuery.when](http://api.jquery.com/jQuery.when) to create a super-Deferred which is resolved when all sub-Deferreds are resolved.

### Wrapping Methods to Wait for a Deferred

On moviepilot.com, methods of several Deferreds are called everywhere throughout the application. It would not be feasible for every caller to check the resolved state and register a callback if necessary. Instead, these methods are wrapped so they can be called safely before the Deferred is resolved. In this case, the calls are automatically saved as `done` callbacks, from later on they are passed through immediately. Of course this wrapping is only possible for asynchronous methods which don’t have a return value but expect a callback function.

The helper method `utils.deferMethods` wraps methods so calls are postponed until a given Deferred object is resolved. The method is quite flexible and we’re using it in several situations.

### Method Call Accumulators

On moviepilot.com, several pieces of information are loaded from external APIs like the Facebook OpenGraph. To reduce the number of HTTP requests, we use again functional magic to automatically accumulate API calls, send them in one batch and distribute the response to the callers. This is a valuable tool for loading additional data without interfering with more important rendering and HTTP communication.

This functionality can be found in `utils.wrapAccumulators` and `utils.createAccumulator`.

### Publish/Subscribe

As mentioned above, Publish/Subscribe is a powerful pattern to promote loose coupling of application modules. Our implementation using `Backbone.Events` is totally simply but highly beneficial.

The Publish/Subscribe pattern is the most important glue in our application because it’s used for most of the cross-module interaction.

## <a name="toc-conclusions">Conclusions</a>

![Ending](http://s3.amazonaws.com/imgly_production/3362023/original.jpg)

By releasing this code into the public, we’d like to start a community discussion on top-level application architecture. “Application” means everything above simple routing, individual models, views and their binding.

Backbone is an easy starting point, but provides only basic, low-level patterns. Especially, Backbone provides little to structure an actual application. For example, the famous “Todo list example” is not an application in the strict sense nor does it teach best practices how to structure Backbone code. In addition, we could not use many of Backbone’s features on moviepilot.com and were forced to re-implement others. For us, Backbone got usable by deriving, extending or even replacing its classes. To be fair, Backbone doesn’t intend to be an all-round framework so it wouldn’t be appropriate to blame Backbone for this deliberate limitations. Nonetheless, most Backbone use cases clearly need a sophisticated application architecture.

The Chaplin structure replaces the Backbone `Router` completely because it’s likely to become the kitchen sink of a Backbone application. Instead we’re using a routing approach similar to Rails. Our router looks like `routes.rb` in a Rails application. Our advice is to separate routing from the actual code which instantiates models and views. For this purpose, we chose to introduce controllers. Further, an application needs to separate the business logic from application state management and view management. For handling top-level UI changes, we introduced the `ApplicationView`.

Due to the asynchronous nature of JavaScript Web applications, much glue is necessary to handle dependencies. We can recommend the techniques we chose: Publish/Subscribe, Deferreds and additional functional magic to wrap, accumulate and defer methods calls.

Last but not least, you will need to think about memory management and garbage collection. We suggest to write proper destructors for every application component. To avoid repetition, you might want to create core classes which allow for automatic disposal.

Apparently, other projects experienced the same Backbone shortcomings and took a similar approach to build an application framework on top of Backbone. See for example:

* [Thorax](http://walmartlabs.github.com/thorax/)
* [Marionette](http://derickbailey.github.com/backbone.marionette/)

## <a name="toc-cast">The Cast</a>

This software was mostly written by:

* Mathias Schäfer ([9elements](http://9elements.com/)) – [mathias.schaefer@9elements.com](mailto:mathias.schaefer@9elements.com) – [@molily](https://twitter.com/molily) – [molily.de](http://molily.de/)
* Johannes Emerich (Moviepilot) – [@knuton](https://twitter.com/knuton) – [johannes.emerich.de](http://johannes.emerich.de/)

With input and contributions from:

* Nico Hagenburger – [@hagenburger](http://twitter.com/hagenburger) – [hagenburger.net](http://www.hagenburger.net/)
* Rin Räuber (9elements) – [@rinpaku](http://twitter.com/rinpaku) – [rin-raeuber.com](http://rin-raeuber.com/)
* Wojtek Gorecki (9elements) – [@newmetl](http://twitter.com/newmetl)
* Jan Monscke (9elements) – [@thedeftone](http://twitter.com/thedeftone)
* Jan Varwig (9elements) – [@agento](http://twitter.com/agento) – [jan.varwig.org](http://jan.varwig.org/)
* Patrick Schneider (9elements) – [@padschneider](http://twitter.com/padschneider) – [padschneider.com](http://padschneider.com/)
* Luis Merino (Moviepilot) – [@rendez](http://twitter.com/rendez)

## <a name="toc-producers">The Producers</a>

The architecture was derived from [moviepilot.com](http://moviepilot.com/), a project by Moviepilot with support from 9elements.

Find out more about Moviepilot: [About Moviepilot.com](http://moviepilot.com/about), [About Moviepilot.de](http://www.moviepilot.de/pages/about).

Find out more about 9elements: [9elements.com](http://9elements.com/), [IO 9elements](http://9elements.com/io/)

Check out more open-source projects by Moviepilot and 9elements: [github.com/moviepilot](https://github.com/moviepilot) and [github.com/9elements](https://github.com/9elements).
