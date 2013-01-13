# Chaplin.SyncMachine

The  `Chaplin.SyncMachine` is a [finite-state machine](http://en.wikipedia.org/wiki/Finite-state_machine) for synchronization of models/collections. There are three states in which a model or collection can be in; unsynced, syncing, and synced. When a state transition (unsynced, syncing, synced, and syncStateChange) occurs Backbone events are called on the model or collection.

## Methods of `Chaplin.SyncMachine`

<a name="syncState"></a>

### syncState

Returns the current synchronization state of the machine.


<a name="isUnsynced"></a>

### isUnsynced

Returns a boolean to determine if model or collection is unsynced.


<a name="isSynced"></a>

### isSynced

Returns a boolean to determine if model or collection is synced.


<a name="isSyncing"></a>

### isSyncing

Returns a boolean to determine if model or collection is currently syncing.


<a name="unsync"></a>

### unsync

Sets the state machine's state to `unsynced` then triggers any events listening for the `unsynced` and `syncStateChanged` events.


<a name="beginSync"></a>

### beginSync

Sets the state machine's state to `syncing` then triggers any events listening for the `syncing` and `syncStateChanged` events.


<a name="beginSync"></a>

### finishSync

Sets the state machine's state to `synced` then triggers any events listening for the `synced` and `syncStateChanged` events.


<a name="abortSync"></a>

### abortSync

Sets state machine's state back to the previous state if the state machine is in the `syncing` state. Then triggers any events listening for the previous state and `syncStateChanged` events.


<a name="unsynced"></a>

### unsynced([callback], [context=this])

Unsynced is a convenience method which will execute a callback in a specified context whenever the state machine enters into the `unsynced` state.

* **callback**: a function to be called when the `unsynced` event occurs
* **context**: the context in which the callback should execute in. Defaults to `this`.


<a name="syncing"></a>

### syncing([callback], [context=this])

Syncing is a convenience method which will execute a callback in a specified context whenever the state machine enters into the `syncing` state.

* **callback**: a function to be called when the `syncing` event occurs
* **context**: the context in which the callback should execute in. Defaults to `this`.


<a name="synced"></a>

### synced([callback], [context=this])

Synced is a convenience method which will execute a callback in a specified context whenever the state machine enters into the `synced` state.

* **callback**: a function to be called when the `synced` event occurs
* **context**: the context in which the callback should execute in. Defaults to `this`.


<a name="syncStateChange"></a>

### syncStateChange([callback], [context=this])

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

    model: Post

    initialize: ->
      super

      # Initialize the SyncMachine
      @initSyncMachine()

      # Will be called on every state change
      @syncStateChange announce

      fetch()

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

Another example of using `SyncMachine` with `Model`:

```coffeescript
class Model extends Chaplin.Model
  _(@prototype).extend Chaplin.SyncMachine

  fetch: (options = {}) ->
    @beginSync()
    success = options.success
    options.success = (model, response) =>
      success? model, response
      @finishSync()
    super

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

## [Code](https://github.com/chaplinjs/chaplin/blob/master/src/chaplin/lib/sync_machine.coffee)
