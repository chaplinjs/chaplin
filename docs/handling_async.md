# Handling Asynchronous Dependencies

Most processes in a client-side JavaScript application run asynchronously. It's quite common for an application to communicate with multiple different external APIs. API bridges are established on demand and of course all API calls are asynchronous. Lazy-loading code and content is a key to performance. Therefore, handling asynchronous dependencies is a big challenge for JavaScript web applications. We're using the following techniques to handle dependencies, from bottom-level to top-level.

## Backbone Events

Model-view-binding, Backbone’s key feature, is still a building block in Chaplin: A view can listen to model changes by subscribing to a `change` event or other custom model events. In addition, collection and collection views can listen for events which occur on their items. This works because model events bubble up to the collection.

## State Machines for Synchronization: Deferreds and SyncMachine

Models, collections and third-party scripts typically have a loaded state. But they're often not ready for use initially because they rely upon asynchronous input such as waiting for data to be fetched from the server or a successful user login.

For this purpose, [jQuery Deferreds](http://api.jquery.com/category/deferred-object/) (or [standalone-deferreds](https://github.com/Mumakil/Standalone-Deferred) if you're using Zepto) could be utilized. They allow registering of load handlers using the [done](http://api.jquery.com/deferred.done/) method. The handlers will be called once the Deferred is resolved.

Deferreds are a versatile pattern which can be used on different levels in an application, but they're rather simple because they only have three states (pending, resolved, rejected) and two transitions (resolve, reject). For more complex synchronization tasks, Chaplin offers the `SyncMachine` which is a state machine.

## Wrapping Methods to Wait for a Deferred

On moviepilot.com, methods of several Deferreds are called everywhere throughout the application. It wouldn't be feasible for every caller to check the resolved state and register a callback if necessary. Instead, these methods are wrapped so they can be called safely before the Deferred is resolved. In this case, the calls are automatically saved as `done` callbacks, from later on they are passed through immediately. Of course this wrapping is only possible for asynchronous methods which don’t have a return value but expect a callback function.

The helper method `utils.deferMethods` in [the Facebook example repository](https://github.com/chaplinjs/facebook-example/blob/master/coffee/lib/utils.coffee) wraps methods so calls are postponed until a given Deferred object is resolved. The method is quite flexible and we’re using it in several situations.

## Publish/Subscribe

The Publish/Subscribe pattern is the most important glue in Chaplin applications because it’s used for most of the cross-module interaction. It’s a powerful pattern to promote loose coupling of application modules. Chaplin’s implementation using `Backbone.Events` is simple but highly beneficial.
