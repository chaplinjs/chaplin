---
layout: default
title: Chaplin.Collection
module_path: src/chaplin/models/collection.coffee
Chaplin: Collection
---

`Chaplin.Collection` is an extension of `Backbone.Collection`. Major additions are disposal for improved memory management and the inclusion of the pub/sub pattern via the `Chaplin.EventBroker` mixin.

<h2 id="methods">Methods</h2>
All [`Backbone.Collection` methods](http://backbonejs.org/#Collection).

<h3 class="module-member" id="serialize">serialize()</h3>
Memory-saving model serialization. Maps models to their attributes recursively. Creates an object which delegates to the original attributes when a property needs to be overwritten.

<h3 class="module-member" id="dispose">dispose()</h3>
Announces to all associated views that the model is being disposed. Unbinds all the global event handlers and also removes all the event handlers on the `Model` module. Removes internal attribute hashes and event handlers. If supported by the runtime, the `Collection` is [frozen](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Object/freeze) to prevent any changes after disposal.

## Usage
To make use of Chaplin’s automatic memory management, use `subscribeEvent` instead of registering methods directly as pub/sub listeners. This forces the handler context so the handler might be removed again on model/collection disposal. It’s crucial to remove all references to model/collection methods to allow them to be garbage collected.
