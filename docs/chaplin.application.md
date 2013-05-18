---
layout: default
title: Chaplin.Application
module_path: src/chaplin/application.coffee
---

The **Chaplin.Application** object is a bootstrapper and a point of extension
for the core modules of **Chaplin**: the **[Dispatcher](#initDispatcher)**, the
**[Layout](#initLayout)**, the **[Router](#initRouter)**, and the
**[Composer](#initComposer)**. The object is inteded to be extended by your
application.  The `initialize` method of your derived class must initialize
the core modules by calling the `initRouter`, `initDispatcher`, `initLayout`,
and then launching navigation with `startRouting`

```coffeescript
Chaplin = require 'chaplin'
routes = require 'routes'

module.exports = class Application extends Chaplin.Application

  initialize: ->
    # No need to call super as the base class method is a no-op.

    # Initialize core components in the required order.
    @initRouter routes
    @initDispatcher()
    @initComposer()
    @initLayout()

    # Actually start routing.
    @startRouting()
```

```javascript
var Chaplin = require('chaplin');
var routes = require('routes');

var Application = Chaplin.Application.extend({
  initialize: function() {
    // Initialize core components in the required order.
    this.initRouter(routes);
    this.initDispatcher();
    this.initComposer();
    this.initLayout();

    // Actually start routing.
    this.startRouting();
  }
});

module.exports = Application;
```

<h2 id="properties">Properties</h2>

<h3 class="module-member" id="title">title</h3>
This is the top-level title that is defaulted into the options hash
forwarded to the layout module. The default title template of the layout
module will append this value to the subtitle passed to the `!adjustTitle`
event to construct the document title.

```coffeescript
# [...]
class Application extends Chaplin.Application
  # [...]
  title: "Fruit"

mediator.publish '!adjustTitle', 'Apple'
# Document title is now "Apple ­— Fruit".
```

```javascript
// [...]
var Application = Chaplin.Application.extend({
  // [...]
  title: 'Fruit'
});
mediator.publish('!adjustTitle', 'Apple');
// Document title is now "Apple ­— Fruit".
```

<h2 id="methods">Methods</h2>

<h3 class="module-member" id="initDispatcher">initDispatcher([options])</h3>
Initializes the **dispatcher** module; forwards passed options to its
contructor. See **[Chaplin.Dispatcher](./chaplin.dispatcher.html)**
for more information.

To replace the dispatcher with a derived class (possibly with various
extensions), you'd override the `initDispatcher` method and construct the
dispatcher class as follows:

```coffeescript
# [...]
Dispatcher = require 'dispatcher'
class Application extends Chaplin.Application
  # [...]
  initDispatcher: (options) ->
    @dispatcher = new Dispatcher options
```

```javascript
// [...]
var Dispatcher = require('dispatcher');
var Application = Chaplin.Application.extend({
  // [...]
  initDispatcher: function(options) {
    this.dispatcher = new Dispatcher(options);
  }
});
```

<h3 class="module-member" id="initRouter">initRouter(routes, [options])</h3>
Initializes the **router** module; forwards passed options to its
constructor. This starts the routing off by checking the current URL against
all defined routes and executes the matched handler. See **[Chaplin.Router](./chaplin.router.html)**
for more information.

* **routes**
  The routing function that contains the match invocations,
  normally located in `routes.coffee`.

To replace the router with a derived class (possibly with various
extensions), you'd override the `initRouter` method and construct the
router class as follows (ensuring to start the routing process as well):

```coffeescript
# [...]
Router = require 'router'
class Application extends Chaplin.Application
  # [...]
  initRouter: (routes, options) ->
    @router = new Router options

    # Register any provided routes.
    routes? @router.match
```

```javascript
// [...]
var Router = require('router');
var Application = Chaplin.Application.extend({
  // [...]
  initRouter: function(routes, options) {
    this.router = new Router(options);

    // Register any provided routes.
    if (routes != null) routes(this.router.match);
  }
});
```

<h3 class="module-member" id="startRouting">startRouting()</h3>
When all of the routes have been matched, call `startRouting()` to
begin monitoring routing events, and dispatching routes. Invoke this method
after all of the components have been initialized as this will also
match the current URL and dispatch the matched route.

<h3 class="module-member" id="initComposer">initComposer([options])</h3>
Initializes the **composer** module; forwards passed options to its
constructor. See **[Chaplin.Composer](./chaplin.composer.html)** for
more information.

To replace the layout with a derived class (possibly with various
extensions), you'd override the `initComposer` method and construct the
composer class as follows:

```coffeescript
# [...]
Composer = require 'composer'
class Application extends Chaplin.Application
  # [...]
  initComposer: (options) ->
    @composer = new Composer options
```

```javascript
// [...]
var Composer = require('composer');
var Application = Chaplin.Application.extend({
  // [...]
  initComposer: function(options) {
    this.composer = new Composer(options);
  }
});
```

<h3 class="module-member" id="initLayout">initLayout([options])</h3>
Initializes the **layout** module; forwards passed options to its
constructor. See **[Chaplin.Layout](./chaplin.layout.html)** for more
information.

To replace the layout with a derived class (possibly with various
extensions), you'd override the `initLayout` method and construct the
layout class as follows:

```coffeescript
# [...]
_ = require 'underscore'
Layout = require 'layout'
class Application extends Chaplin.Application
  # [...]
  initLayout: (options) ->
    @layout = new Layout _.defaults options, {@title}
```

```javascript
// [...]
var _ = require('underscore');
var Layout = require('layout');
var Application = Chaplin.Application.extend({
  // [...]
  initLayout: function(options) {
    this.layout = new Layout(_.defaults(options, {title: this.title}));
  }
});
```
