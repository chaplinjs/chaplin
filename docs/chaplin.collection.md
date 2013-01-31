# [Chaplin.Collection](src/chaplin/models/collection.coffee)

`Chaplin.Collection` extends the standard `Backbone.Collection`. It adds disposal for cleaning up and the Pub/Sub pattern via the `Chaplin.EventBroker` mixin.

`Chaplin.Collection` also has `addAtomic` for adding several items while fireing a `reset` event.

## Methods of `Chaplin.Collection`
All `Backbone.Collection` [methods](http://backbonejs.org/#Collection).

TODO

## Usage
Please do not register their methods directly as Pub/Sub listeners, use `subscribeEvent` instead. This forces the handler context so the handler might be removed again on model/collection disposal. It’s crucial to remove all references to model/collection methods to allow them to be garbage collected.
