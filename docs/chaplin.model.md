---
layout: default
title: Chaplin.Model
module_path: src/chaplin/models/model.coffee
Chaplin: Model
---

`Chaplin.Model` is an extension of `Backbone.Model`. Major additions are disposal for improved memory management and the inclusion of the pub/sub pattern via the `Chaplin.EventBroker` mixin.

<h2 id="methods">Methods</h2>
All `Backbone.Model` [methods](http://backbonejs.org/#Model).

<h3 class="module-member" id="getAttributes">getAttributes()</h3>
An accessor for the model’s `attributes` property. The accessor can be overwritten by decorators to optionally perform any kind of processing of the data.

**Note:** Pay attention to the fact that this returns the actual `attributes` object, not a serialization.

<h3 class="module-member" id="serialize">serialize()</h3>
Memory-saving serializing of model attributes. Maps models to their attributes recursively. Creates an object which delegates to the original attributes when a property needs to be overwritten.

<h3 class="module-member" id="dispose">dispose()</h3>
Sends a `'dispose'` event to all associated collections and views to announce that the model is being disposed. Unsubscribes all global and local event handlers and also removes all the event handlers that were subscribed to this model’s events. Removes the collection reference, internal attribute hashes and event handlers. On compliant runtimes the model is frozen to prevent any further changes to it, see [Object.freeze](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Object/freeze).

## Usage
To take advantage of the built in memory management, use `subscribeEvent` instead of registering model methods directly as handlers for global events. This ensures that the handler is added in a way that allows for automatic removal on model/collection disposal. It’s crucial to remove all references to model/collection methods to allow them to be garbage collected.

The `SyncMachine` mixin for models simplifies the handling of asynchronous data fetching. Its functionality can be included with a simple `_.extend`: <span class="coffeescript">`_.extend @prototype, Chaplin.SyncMachine`</span> <span class="javascript">`_.extend(this.prototype, Chaplin.SyncMachine);`</span>. To learn more about `SyncMachine`, see the [SyncMachine docs](./chaplin.sync_machine.html).
