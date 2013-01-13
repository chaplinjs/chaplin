# Chaplin.Model

`Chaplin.Model` extends the standard `Backbone.Model`. It adds disposal for cleaning up and the Pub/Sub pattern via the `Chaplin.EventBroker` mixin.

## Methods of `Chaplin.Model`
All `Backbone.Model` [methods](http://backbonejs.org/#Model).

<a name="initDeferred"></a>

### initDeferred

Creates a new [jQuery Deferred object](http://api.jquery.com/category/deferred-object/) instance.

<a name="getAttributes"></a>

### getAttributes

Gets the attributes from the view template and can be overwritten by decorators which cannot create a proper 'attributes' getter due to the absence of getters and setters in ECMAScript 3.


<a name="serialize"></a>

### serialize([model])

Maps models to their attributes recursively. Creates an object which delegates to the original attributes when a property needs to be overwritten.

* **model**: A model which needs to be serialized

<a name="dispose"></a>

### dispose

Announces to all associated collections and views that the model is being disposed. Unbinds all the global event handlers and also removes all the event handlers on the Model module. If the model is a Deferred, it will be rejected.  Removes the collection reference, internal attribute hashes and event handlers.  Attempts to freeze the Model to prevent any changes to the Model. See [Object.freeze](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Object/freeze).

## Usage
Please do not register their methods directly as Pub/Sub listeners, use `subscribeEvent` instead. This forces the handler context so the handler might be removed again on model/collection disposal. It’s crucial to remove all references to model/collection methods to allow them to be garbage collected.

It is also good to have `SyncMachine` mixed to models for handling asynchronous data fetching. Mixing can be done by simple `_.extend`: `_(@prototype).extend Chaplin.SyncMachine`. See [SyncMachine docs](docs/chaplin.sync_machine.md) for code.

## [Code](https://github.com/chaplinjs/chaplin/blob/master/src/chaplin/models/model.coffee)
