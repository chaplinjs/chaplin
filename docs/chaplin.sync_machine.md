---
layout: default
title: Chaplin.SyncMachine
module_path: src/chaplin/lib/sync_machine.coffee
---

The  `Chaplin.SyncMachine` is a [finite-state machine](http://en.wikipedia.org/wiki/Finite-state_machine) for synchronization of models/collections. There are three states in which a model or collection can be in; unsynced, syncing, and synced. When a state transition (unsynced, syncing, synced, and syncStateChange) occurs Backbone events are called on the model or collection.

<h2 id="methods">Methods</h2>

<h3 class="module-member" id="syncState">syncState</h3>

Returns the current synchronization state of the machine.

<h3 class="module-member" id="isUnsynced">isUnsynced</h3>

Returns a boolean to determine if model or collection is unsynced.

<h3 class="module-member" id="isSynced">isSynced</h3>

Returns a boolean to determine if model or collection is synced.

<h3 class="module-member" id="isSyncing">isSyncing</h3>

Returns a boolean to determine if model or collection is currently syncing.

<h3 class="module-member" id="unsync">unsync</h3>

Sets the state machine's state to `unsynced` then triggers any events listening for the `unsynced` and `syncStateChange` events.

<h3 class="module-member" id="beginSync">beginSync</h3>

Sets the state machine's state to `syncing` then triggers any events listening for the `syncing` and `syncStateChange` events.

<h3 class="module-member" id="finishSync">finishSync</h3>

Sets the state machine's state to `synced` then triggers any events listening for the `synced` and `syncStateChange` events.

<h3 class="module-member" id="abortSync">abortSync</h3>

Sets state machine's state back to the previous state if the state machine is in the `syncing` state. Then triggers any events listening for the previous state and `syncStateChange` events.

<h3 class="module-member" id="unsynced">unsynced([callback], [context=this])</h3>

Unsynced is a convenience method which will execute a callback in a specified context whenever the state machine enters into the `unsynced` state.

* **callback**: a function to be called when the `unsynced` event occurs
* **context**: the context in which the callback should execute in. Defaults to `this`.

<h3 class="module-member" id="syncing">syncing([callback], [context=this])</h3>

Syncing is a convenience method which will execute a callback in a specified context whenever the state machine enters into the `syncing` state.

* **callback**: a function to be called when the `syncing` event occurs
* **context**: the context in which the callback should execute in. Defaults to `this`.

<h3 class="module-member" id="synced">synced([callback], [context=this])</h3>

Synced is a convenience method which will execute a callback in a specified context whenever the state machine enters into the `synced` state.

* **callback**: a function to be called when the `synced` event occurs
* **context**: the context in which the callback should execute in. Defaults to `this`.

<h3 class="module-member" id="syncStateChange">syncStateChange([callback], [context=this])</h3>

SyncStateChange is a convenience method which will execute a callback in a specified context whenever the state machine changes state.

* **callback**: a function to be called when the state of machine occurs.
* **context**: the context in which the callback should execute in. Defaults to `this`.

## Usage

The `Chaplin.SyncMachine` is a dependency of `Chaplin.Model` and `Chaplin.Collection` and should be used for complex synchronization of models and collections.  An example of this would be using a 3rd party.

```coffeescript
define [
  'chaplin'
  'models/post' # Post model
], (Chaplin.Collection, Post) ->

  class Posts extends Chaplin.Collection
    # Initialize the SyncMachine
    _.extend @prototype, Chaplin.SyncMachine

    model: Post

    initialize: ->
      super

      # Will be called on every state change
      @syncStateChange announce

      @fetch()

    # Custom fetch method which warrents
    # the sync machine
    fetch: =>

      #Set the machine into `syncing` state
      @beginSync()

      # Do something interesting like calling
      # a 3rd party service
      $.get 'http://some-service.com/posts', @processPosts

    processPosts: (response) =>
      # Exit if for some reason this collection was
      # disposed prior to the response
      return if @disposed

      # Update the collection
      @reset(if response and response.data then response.data else [])

      # Set the machine into `synced` state
      @finishSync()

    announce: =>
      console.debug 'state changed'
```

```javascript
define([
  'chaplin',
  'models/post' // Post model
], function(Chaplin.Collection, Post) {

  var Posts = Chaplin.Collection.extend({
    model: Post,

    initialize: function() {
      Chaplin.Collection.prototype.initialize.apply(this, arguments);

      // Initialize the SyncMachine
      _.extend(this, Chaplin.SyncMachine);

      // Will be called on every state change
      this.syncStateChange(this.announce.bind(this));

      this.fetch();
    },

    // Custom fetch method which warrents
    // the sync machine
    fetch: function() {
      // Set the machine into `syncing` state
      this.beginSync()

      // Do something interesting like calling
      // a 3rd party service
      $.get('http://some-service.com/posts', this.processPosts.bind(this))
    },

    processPosts: function(response) {
      // Exit if for some reason this collection was
      // disposed prior to the response
      if (this.disposed) return;

      // Update the collection
      this.reset((response && response.data) ? response.data : []);

      // Set the machine into `synced` state
      this.finishSync();
    },

    announce: function() {
      console.debug('state changed');
    }
  });

  return Posts;
```

Another example of using `SyncMachine` with `Model`:

```coffeescript
class Model extends Chaplin.Model
  _.extend @prototype, Chaplin.SyncMachine

  fetch: (options = {}) ->
    @beginSync()
    success = options.success
    options.success = (model, response) =>
      success? model, response
      @finishSync()
    super options

# Will render view when model data will arrive from server.
class View extends Chaplin.View
  rendered: no
  initialize: ->
    super
    # Render.
    @model.synced =>
      unless @rendered
        @render()
        @rendered = yes

...

model = new Model
view = new View {model}
model.fetch()
```

```javascript
var Model = Chaplin.Model.extend({
  initialize: function() {
    Chaplin.Model.prototype.initialize.apply(this, arguments);
    _.extend(this, Chaplin.SyncMachine);
  },

  fetch: function(options) {
    if (options == null) options = {};
    this.beginSync();
    var success = options.success;

    options.success = (function(model, response) {
      success? model, response
      if (typeof success === 'function') success(model, response);
      this.finishSync();
    }).bind(this)

    Chaplin.Model.prototype.fetch.call(this, options);
  }
});

// Will render view when model data will arrive from server.
var View = Chaplin.View.extend({
  rendered: false,
  initialize: function() {
    Chaplin.View.prototype.initialize.apply(this, arguments);
    // Render.
    this.model.synced((function() {
      if (!this.rendered) {
        this.render();
        this.rendered = true;
      }
    }).bind(this));
  }
});
...

var model = new Model;
var view = new View({model: model});
model.fetch();
```
