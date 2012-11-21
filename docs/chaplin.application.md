# Chaplin.Application

The `Chaplin.Application` is a bootstrapper which provides methods to start other core modules as needed:
* `Router`
* `Dispatcher`
* `Layout`

## Methods of `Chaplin.Application`

<a name="initDispatcher"></a>

### initDispatcher( [options={}] )
Initialize `Chaplin.Dispatcher`. Look at `Chaplin.Dispatcher` [documentation](./chaplin.dispatcher.md) for more details about the options.

* **options**: the option for the Dispatcher

<a name="initLayout"></a>

### initLayout( [options={}] )
Initialize `Chaplin.Layout`. [Chaplin.Layout documentation](./chaplin.layout.md)

* **options**: none for now.


<a name="initRouter"></a>

### initRouter( routes, [options={}] )
Initialize `Chaplin.Router`. [Chaplin.Router documentation](./chaplin.router.md)

* **routes**: the routes defined in the routes file
* **options**: none

## Usage
The `Chaplin.Application` is intended to be extended by your Application. The `initialize` method instanciate the `Chaplin.Dispatcher`, `Chaplin.Layout` and `Chaplin.Router` by calling the `Chaplin.Application.init*` methods:

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

      # Initialize core components
      @initDispatcher()
      @initLayout()
      @initRouter routes
```

In this example, we don't extend the Layout but it is likely that you will need to. In this case, you will load it as a dependency and overwrite the `initLayout` (or skip it):

```coffeescript
define [
  'chaplin',
  'views/layout' # our extend Layout
], (Chaplin, Layout) ->
  'use strict'

  class MyApplication extends Chaplin.Application

    title: 'The title for your application'

    initialize: ->
      # ...

      @layout = new Layout {@title} # option 1:  directly instantiate the Layout
      # OR
      @initLayout()                 # option 2: we still call initLayout...

    initLayout: ->                  #           ... and overwrite it to load the good Layout
      @layout = new Layout {@title}
```

## [Code](https://github.com/chaplinjs/chaplin/blob/master/src/chaplin/application.coffee)
