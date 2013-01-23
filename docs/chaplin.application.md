# [Chaplin.Application](./../src/chaplin/application.coffee)

The **Chaplin.Application** object is a bootstrapper and a point of extension
for the core modules of **Chaplin**: the **[Dispatcher][]**, the **[Layout][]**,
and the **[Router][]**. The object is inteded to be extended by your
application. The `initialize` method of your derived class must initialize
the core modules by calling the `initDispatcher`, `initLayout`,
and `initRouter` (`initRouter` should be invoked last).

```coffeescript
Chaplin = require 'chaplin'
routes = require 'routes'

module.exports = class Application extends Chaplin.Application

  initialize: ->
    # No need to call super as the base class method is a no-op.

    # Initialize core components in the required order.
    @initDispatcher()
    @initLayout()
    @initRouter routes
```

[Dispatcher]: #initdispatcheroptions
[Layout]: #initlayoutoptions
[Router]: #initrouterroutes-options

### Properties

##### [title](./../src/chaplin/application.coffee#L22)
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

### Methods

##### [initDispatcher([options])](./../src/chaplin/application.coffee#L31)
Initializes the **dispatcher** module; forwards passed options to its
contructor. See **[Chaplin.Dispatcher][]** for more information.

[Chaplin.Dispatcher]: ./chaplin.dispatcher.md

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

##### [initLayout([options])](./../src/chaplin/application.coffee#L34)
Initializes the **layout** module; forwards passed options to its
constructor. See **[Chaplin.Layout][]** for more information.

[Chaplin.Layout]: ./chaplin.layout.md

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

##### [initRouter(routes, [options])](./../src/chaplin/application.coffee#L42)
Initializes the **router** module; forwards passed options to its
constructor. This starts the routing off by checking the current URL against
all defined routes and executes the matched handler. See **[Chaplin.Router][]**
for more information.

* **routes** <br />
  The routing function that contains the match invocations,
  normally located in `routes.coffee`.

[Chaplin.Router]: ./chaplin.router.md

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
    routes? @router.match
    @router.startHistory()
```
