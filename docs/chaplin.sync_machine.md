---
layout: default
title: Chaplin.SyncMachine
module_path: src/chaplin/lib/sync_machine.coffee
Chaplin: SyncMachine
---

The  `Chaplin.SyncMachine` is a [finite-state machine](http://en.wikipedia.org/wiki/Finite-state_machine) for synchronization of models/collections. There are three states in which a model or collection can be in; unsynced, syncing, and synced. When a state transition (unsynced, syncing, synced, and syncStateChange) occurs, Backbone events are called on the model or collection.

<h2 id="methods">Methods</h2>

<h3 class="module-member" id="syncState">syncState</h3>

Returns the current synchronization state of the machine.

<h3 class="module-member" id="isUnsynced">isUnsynced</h3>

Returns a boolean to help determine if the model or collection is unsynced.

<h3 class="module-member" id="isSynced">isSynced</h3>

Returns a boolean to help determine if the model or collection is synced.

<h3 class="module-member" id="isSyncing">isSyncing</h3>

Returns a boolean to help determine if the model or collection is currently syncing.

<h3 class="module-member" id="unsync">unsync</h3>

Sets the state machine’s state to `unsynced`, then triggers any events listening for the `unsynced` and `syncStateChange` events.

<h3 class="module-member" id="beginSync">beginSync</h3>

Sets the state machine’s state to `syncing`, then triggers any events listening for the `syncing` and `syncStateChange` events.

<h3 class="module-member" id="finishSync">finishSync</h3>

Sets the state machine’s state to `synced`, then triggers any events listening for the `synced` and `syncStateChange` events.

<h3 class="module-member" id="abortSync">abortSync</h3>

Sets the state machine’s state back to the previous state if the state machine is in the `syncing` state. Then triggers any events listening for the previous state and `syncStateChange` events.

<h3 class="module-member" id="unsynced">unsynced([callback], [context=this])</h3>

`unsynced` is a convenience method which will execute a callback in a specified context whenever the state machine enters into the `unsynced` state.

* **callback**: a function to be called when the `unsynced` event occurs
* **context**: the context in which the callback should execute in. Defaults to `this`.

<h3 class="module-member" id="syncing">syncing([callback], [context=this])</h3>

`syncing` is a convenience method which will execute a callback in a specified context whenever the state machine enters into the `syncing` state.

* **callback**: a function to be called when the `syncing` event occurs
* **context**: the context in which the callback should execute in. Defaults to `this`.

<h3 class="module-member" id="synced">synced([callback], [context=this])</h3>

`synced` is a convenience method which will execute a callback in a specified context whenever the state machine enters into the `synced` state.

* **callback**: a function to be called when the `synced` event occurs
* **context**: the context in which the callback should execute in. Defaults to `this`.

<h3 class="module-member" id="syncStateChange">syncStateChange([callback], [context=this])</h3>

`syncStateChange` is a convenience method which will execute a callback in a specified context whenever the state machine changes state.

* **callback**: a function to be called when a state change occurs.
* **context**: the context in which the callback should execute in. Defaults to `this`.

## Usage

The `Chaplin.SyncMachine` is a dependency of `Chaplin.Model` and `Chaplin.Collection` and should be used for complex synchronization of models and collections. As an example, think of making requests to you own REST API or some third party web service.

```coffeescript
class Model extends Chaplin.Model
  _.extend @prototype, Chaplin.SyncMachine

  initialize: ->
    super
    @on 'request', @beginSync
    @on 'sync', @finishSync
    @on 'error', @unsync

...

# Will render view when model data will arrive from server.
model = new Model
view = new Chaplin.View {model}
model.fetch().then view.render
```

```javascript
var Model = Chaplin.Model.extend({
  initialize: function() {
    Chaplin.Model.prototype.initialize.apply(this, arguments);
    this.on('request', this.beginSync);
    this.on('sync', this.finishSync);
    this.on('error', this.unsync);
  }
});

_.extend(Model.prototype, Chaplin.SyncMachine);

...

// Will render view when model data will arrive from server.
var model = new Model;
var view = new Chaplin.View({model: model});
model.fetch().then(view.render);
```

You can do the same to `Collection`.

More complex example involving `Collection`:

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
