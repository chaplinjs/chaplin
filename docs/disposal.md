# Memory Management and Object Disposal

A core concern of the Chaplin architecture is a proper memory management. While there isn’t a broad discussion about garbage collection in JavaScript applications, it’s an important topic. Since Backbone provides little out of the box to manage memory, Chaplin extends Backbone's Model, Collection and View classes to implement a powerful disposal process which ensures that each controller, model, collection and view cleans up after itself.

Event handling creates references between objects. If a view listens for changes in a model, that model will have a reference to the view method in its internal `_callbacks` list. View methods are often bound to the view instance using `Function.prototype.bind`, `_.bind()`, CoffeeScript’s fat arrow `=>` or alike. When a `change` handler is bound to the view, the view will remain in memory even if it's already detached from the DOM. The garbage collector can’t free its memory because of this reference.

Before a new controller takes over and the user interface changes, the `dispose` method of the current controller is invoked:

- The controller calls `dispose` on its models/collections and then removes references to them.
- On disposal, a model clears all of its attributes and disposes all associated views.
- A view's 'dispose' method removes all of its DOM elements, unsubscribes from DOM or model/collection events and calls 'dispose' on its subviews.
- Models/collections and views unsubscribe from global Publish/Subscribe events.

This disposal process is quite complex and many objects needs a custom `dispose` method. But this is just the least Chaplin can do.
