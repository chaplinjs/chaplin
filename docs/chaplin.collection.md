---
layout: default
title: Chaplin.Collection
module_path: src/chaplin/models/collection.coffee
---

`Chaplin.Collection` extends the standard `Backbone.Collection`. It adds disposal for cleaning up and the Pub/Sub pattern via the `Chaplin.EventBroker` mixin.

<h2 id="methods">Methods</h2>
All `Backbone.Collection` [methods](http://backbonejs.org/#Collection).

<h3 class="module-member" id="serialize">serialize()</h3>
Memory-saving serializing of models. Maps models to their attributes recursively. Creates an object which delegates to the original attributes when a property needs to be overwritten.

<h3 class="module-member" id="dispose">dispose()</h3>
Announces to all associated views that the model is being disposed. Unbinds all the global event handlers and also removes all the event handlers on the Model module. Removes internal attribute hashes and event handlers. Attempts to [freeze](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Object/freeze) the Collection to prevent any changes to the Collection.

## Usage
Please do not register their methods directly as Pub/Sub listeners, use `subscribeEvent` instead. This forces the handler context so the handler might be removed again on model/collection disposal. It’s crucial to remove all references to model/collection methods to allow them to be garbage collected.
