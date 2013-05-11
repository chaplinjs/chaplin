---
layout: default
title: Chaplin.Controller
module_path: src/chaplin/controllers/controller.coffee
---

A controller is the place where a model/collection and its associated views are instantiated. It’s also in charge of model and view disposal when another controller takes over. There can be one current controller which provides the main view and represents the current URL. In addition, there can be several persistent controllers for central tasks, like for example a `SessionController`.

## Methods of `Chaplin.Controller`

### adjustTitle(subtitle)
Adjusts document title to `subtitle - title`. Title template can be set when initializing `Dispatcher`.

### redirectTo(url, options)

Navigates to `url` in app.

### redirectToRoute(name, params, options)

Navigates to named route, like `@redirectToRoute 'likes#show', id: 502`.

### dispose()

Disposes all models and views on current `Controller` instance.

## Usage

### Structure

By convention, there is a controller for each application module. A controller may provide several action methods like `index`, `show`, `edit` and so on. These actions are called by the [Chaplin.Dispatcher](./chaplin.dispatcher.html) when a route matches.

A controller is usually started following a route match. A route points to controller action, for example `likes#show`, which is the `show` action of the `LikesController`.


### Naming convention

By default, all controllers must be placed into the `/controllers/`  folder (the / stands for the root of the `baseURL` you have defined for your loader) and be suffixed with `_controller`. So for instance, the `LikesController` needs to be defined in the file `/controllers/likes_controller.js`.

If you want to overwrite this behaviour, you can edit the `controller_path` and `controller_suffix` options in the options hash you pass to `Chaplin.Application.initDispatcher` or `Chaplin.Dispatcher.initialize`. See details in the `Chaplin.Dispatcher` [documentation](./chaplin.dispatcher.html#toc_1).


### Before actions

To execute code before the controller action is called, you can use the `beforeAction` object (e.g. to add access control checks).


### Example

```coffeescript
define [
  'controllers/controller',
  'models/likes',          # the collection
  'models/like',           # the model
  'views/likes-view',      # the collection view
  'views/full-like-view'   # the view
], (Controller, Likes, Like, LikesView, FullLikeView) ->
  'use strict'

  class LikesController extends Controller
    beforeAction: (params, route) ->
      if route.action is 'show'
        @redirectUnlessLoggedIn()

    # Initialize method is empty here.
    index: (params) ->
      @collection = new Likes()
      @view = new LikesView {@collection}

    show: (params) ->
      @model = new Like id: params.id
      @view = new FullLikeView {@model}
```

```javascript
define([
  'controllers/controller',
  'models/likes',          // the collection
  'models/like',           // the model
  'views/likes-view',      // the collection view
  'views/full-like-view'   // the view
], function(Controller, Likes, Like, LikesView, FullLikeView) {
  'use strict'

  var LikesController = Controller.extend({
    beforeAction: function() {
      this.redirectUnlessLoggedIn();
    },

    // Initialize method is empty here.
    index: function(params) {
      this.collection = new Likes();
      this.view = new LikesView({collection: this.collection});
    },

    show: function(params) {
      this.model = new Like({id: params.id});
      this.view = new FullLikeView({model: this.model});
    }
  });
  return LikesController;
});
```

### Creating models and views

A controller action should create a main view and save it as an instance property named `view`: `this.view = new SomeView(…)`.

Normal models and collection should also be saved as instance properties so Chaplin can reach them.

### Controller disposal and object persistence

Per default, a controller is instantiated afresh with every route match. That means models and views are disposed by default even if the new controller is the same as the old controller.

To persist models and views in a controlled way, it is recommended to use the [Chaplin.Composer](./chaplin.composer.html).

Chaplin will automatically dispose all models and views that are properties of the controller instance. If you’re using the Composer to reuse models and views, please use local variables instead of controller properties. Otherwise Chaplin will dispose them.

### Including Controllers in the production build

In your production environment, you may want to package your files together using a build tool like [r.js](http://requirejs.org/docs/optimization.html).

Controllers are dynamically loaded from the `Chaplin.Dispatcher` using the `require()` method. Build tools like r.js can’t know about files that are lazy-loaded using `require()`. They only consider the static dependencies specified by `define()`.

This means that build tools will ignore your controllers and won’t include them in your package. You need to include them manually, for instance with r.js:

```yaml
paths:
  # ...
modules:
  - name: 'application'
  - name: 'controllers/one_controller'       # included manually into the build
  - name: 'controllers/another_controller'   # same
```
