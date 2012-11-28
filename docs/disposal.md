# Memory Management and Object Disposal

One of the core concerns of the Chaplin architecture is a proper memory management. There isn’t a broad discussion about garbage collection in JavaScript applications, but in fact it’s an important topic. Backbone provides little out of the box so Chaplin ensures that every controller, model, collection and view cleans up after itself.

Event handling creates references between objects. If a view listens for model changes, the model has a reference to a view method in its internal `_callbacks` list. View methods are often bound to the view instance using `Function.prototype.bind`, `_.bind()`, CoffeeScript’s fat arrow `=>` or alike. When a `change` handler is bound to the view, the view will remain in memory even if it was already detached from the DOM. The garbage collector can’t free its memory because of this reference.

Before a new controller takes over and the user interface changes, the `dispose` method of the current controller is invoked. The controller calls `dispose` on its models/collections and then removes references to them. On disposal, a model clears all its attributes and disposes all associated views. A view removes all DOM elements and unsubscribes from DOM or model/collection events. Models/collections and views unsubscribe from global Publish/Subscribe events.

This disposal process is quite complex and many objects needs a custom `dispose` method. But this is just the least Chaplin can do.
