# Overview
**Chaplin** empowers you to **quick**ly develop **single-page**, **scalable**
web applications; and allows you to focus on designing and developing
the underlying functionality in your web application.

## Architecture
Chaplin is an architecture for JavaScript web applications using
the [Backbone.js][] library. The code is originally derived
from [moviepilot.com][], a large single-page application.

While Backbone is an easy starting point, it provides only basic,
low-level patterns. Backbone provides little structure above
simple routing, individual models, views and their binding. Chaplin addresses
these limitations by providing a light-weight but flexible structure which
leverages well-proven design patterns and best practises.

[Backbone.js]: http://documentcloud.github.com/backbone/
[moviepilot.com]: http://moviepilot.com/

## Framework
##### [Application][]
The bootstrapper of the application; an extension point for key
parts of the architecture.

[Application]: ./chaplin.application.md

##### [Router][]
Facilitates mapping URLs to controller actions based on a
user-defined configuration file. It is reponsible for observing and acting
upon URL changes. It does no direct action apart from notifiying the dispatcher
of such a change however.

###### Routes
By convention, routes should be declared in a separate module (typically
`routes.coffee`). For example:

```coffee
match 'likes/:id', 'likes#show'
```

This works much like the [Ruby on Rails counterpart][]. If a route matches,
a `matchRoute` event is published passing a `params` hash which contains
pattern matches (like `id` in the example above) and additional GET parameters
parsed from the query string. This hands control over to the **Dispatcher**.

[Ruby on Rails counterpart]: http://guides.rubyonrails.org/routing.html
[Router]: ./chaplin.router.md

##### [Dispatcher][]
Between the router and the controllers, there is the **Dispatcher** listening
for routing events. On such events, it loads the target controller, creates an
instance of it and calls the target action. The action is actually a method
of the controller. The previously active controller is automatically disposed.

[Dispatcher]: ./chaplin.dispatcher.md

##### [Layout][]
The `Layout` is the top-level application view. When a new controller is
activated, the `Layout` is responsible for changing the main view to the
view of the new controller.

In addition, the `Layout` handles the activation of internal links. That is,
you can use a normal `<a href="/foo">` element to link to another
controller module.

Furthermore, top-level DOM events on `window` or `document`, should be
registered here.

[Layout]: ./chaplin.layout.md

##### [mediator][]
The mediator is an event broker that implements the [Publish/Subscribe]()
design pattern. It should be used for most of the inter-module communication
in Chaplin applications. Modules can emit events using `this.publishEvent`
in order to notify other modules, and listen for such events
using `this.subscribeEvent`. The mediator can also be used to easily share data
between several modules, like a user model or other
persistent and globally accessible data.

[Publish/Subscribe]: http://en.wikipedia.org/wiki/Publish/Subscribe
[mediator]: ./chaplin.mediator.md

##### [Controller][]
A controller is the place where a model and associated views are instantiated.
Typically, a controller represents one screen of the application. There can be
one current controller which provides the main view and represents the
current URL.

By convention, there is a controller for each application module. A controller
may provide several action methods like `index`, `show`, `edit` and so on.
These actions are called by the `Dispatcher` when a route matches.

[Controller]: ./chaplin.controller.md

##### [Model][]
Holds reference to the data and contains any logic neccessary to retrieve the
data from its source and optionally send it back.

[Model]: ./chaplin.model.md

##### [Collection][]
A collection of models. Contains logic to provide client-side filtering and
sorting of them.

[Collection]: ./chaplin.collection.md

##### [View][]
Provides the logic that drives the user interface such as responding to DOM
events and mapping data from the model to a template.

[View]: ./chaplin.view.md

##### [Collection View][]
Maps to a collection to generate a list of item views that are bound to
the models in the collection.

[Collection View]: ./chaplin.collection.view.md

## Flow
Every Chaplin application starts with a class that inherits
from `Application`. This is merely a bootstrapper which instantiates and
configures the four core moules: **Dispatcher**, **Layout**, **mediator**, and
**Router** (in that order).

After creating the **Router**, the routes are registered. Usually they are
read from a configuration file called  `routes.{coffee,js}`. A route maps a
URL pattern to a controller action. For example, the path `/` can be mapped to
the `index` action of the `HomeController`.

After the **Application** invokes `initRouter`; the **Router** starts to
observe the current URL. If a route matches, it notifies the other modules.

This is where the **Dispatcher** takes over. It loads the target controller
and its dependencies (e.g. `HomeController`). Then, the controller is
instantiated and the controller action is called (e.g. `index`). An *action*
is a method of the controller. The **Dispatcher** also keeps track of the
currently active controller, and disposes the previously active controller.

Typically, a controller creates a **Model** or **Collection** and
a corresponding **View**. The model or collection may fetch some data
from the server which is then rendered by the view. By convention,
the models, collection and views are saved as properties on
the controller instance.

## [Memory Management][]
A core concern of the Chaplin architecture is proper memory management. While
there isn’t a broad discussion about garbage collection in JavaScript
applications, it’s an important topic. In event-driven systems, registering
events creates references between objects. If these references aren’t removed
when a module is no longer in use, the garbage collector can’t free the memory.

Since Backbone provides little out of the box to manage memory, Chaplin extends
Backbone's Model, Collection and View classes to implement a powerful disposal
process which ensures that each controller, model, collection and view cleans
up after itself.

[Memory Management]: ./disposal.md

![Ending](http://s3.amazonaws.com/imgly_production/3362023/original.jpg)
