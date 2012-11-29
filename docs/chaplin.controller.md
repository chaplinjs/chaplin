# Chaplin.Controller

A controller is the place where a model/collection and an associated views are instantiated. It is also in charge of model and view disposal when another controller takes over. There can be one current controller which provides the main view and represents the current URL. In addition, there can be several persistent controllers which govern special views like a header, a navigation sidebar or a footer.

## Methods of `Chaplin.Controller`

Chaplin.Controller doesn't provide public methods. See the usage below:

## Usage

### Naming convention

By default, all controllers must be placed into the `/controllers/` (the / stands for the root of the baseURL you have defined for your loader) folder and be suffixed with `_controller`. So for instance, the `LikeController` will be in the file `/controllers/like_controller.js`.

If you want to overwrite this behaviour, you can edit the `controller_path` and `controller_suffix` options in the options hash you pass to `Chaplin.Application.initDispatcher` or `Chaplin.Dispatcher.initialize`. See details in the `Chaplin.Dispatcher` [documentation](./chaplin.dispatcher.md#initialize).


### Structure

By convention, there is a controller for each application module. A controller may provide several action methods like `index`, `show`, `edit` and so on. These actions are called by the [Chaplin.Dispatcher](./chaplin.dispatcher.md) when a route matches.

Most of the time, a controller is started following a route match. In this case, the URL representing the application state is already given. But a controller can also be started programatically by publishing a `!startupController` event. In this case, the URL has to be determined. This is the purpose of the `historyURL` method.


### Example

```coffeescript
define [
  'controllers/controller',
  'models/likes',          # the collection
  'models/like',           # the model
  'views/likes_view',      # the collection view
  'views/full_like_view'   # the view
], (Controller, Likes, Like, LikesView, FullLikeView) ->

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


### Warning 1: Controller persistence

Per default, a controller is instantiated afresh with every route match. That means models and views are disposed by default even if the new controller is the same as the old controller. To persist models and views, it is recommended to save them in a central store, not on the controller instances.


### Warning 2: Application build

When you go in production, you may want to package your javascript files togethers using a build tool like `r.js`.

Controllers are dynamically loaded from the `Chaplin.Dispatcher` using the `require()` method. Build tools (like r.js) ignore the files loaded in the code using the `require()` method and only consider the one in the `define()` one.

It means that build tools will ignore your controllers and won't include them in your package. You need to include them manually, for instance with r.js:

```yaml
paths:
  # ...
modules:
  - name: 'application'
  - name: 'controllers/one_controller'       # included manually into the build
  - name: 'controllers/another_controller'   # same
```

## [Code](https://github.com/chaplinjs/chaplin/blob/master/src/chaplin/controllers/controller.coffee)
