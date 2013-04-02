# Event Handling

For models and views, there are several wrapper methods for event handler registration.
In contrast to the direct methods, they will save memory because the handlers will
be removed correctly once the model or view is disposed. The methods will also be bound
to the caller for ease of registration.

## Mediator

Global events use the `mediator` as an event channel. On most objects
in chaplin (including models, views, and controllers), there are shortcuts
for manipulating global events. These methods are mixed into eventable objects by way of the [EventBroker][].

[EventBroker]: https://github.com/chaplinjs/chaplin/blob/master/docs/chaplin.event_broker.md

```coffeescript
@subscribeEvent 'dispatcher:dispatch', @dispatch
@subscribeEvent '!router:route', -> console.log arguments...
```

These are aliased to `Chaplin.mediator.*` with the additional benefit of automatically
invoking `Chaplin.mediator.unsubscribe` in the `dispose` method of the eventable and providing some small
type checking.

## Eventable

In views, the standard `@model.on` way to register a handler for a model event should not be used. Use the memory-saving wrapper `listenTo` instead:

```coffeescript
@listenTo @model, 'add', @doSomething
```

In a model, it’s fine to use `on` directly as long as the handler is a method of the model itself.

## User Input

Most views handle user input by listening to DOM events. Backbone provides the `events` property to register event handlers declaratively. But this does not work nicely when views inherit from each other and a specific view needs to handle additional events.

Chaplin’s `View` class provides the `delegate` method as a shortcut for `@$el.on`. It has the same signature as the jQuery 1.7 `on` method. Some examples:

```coffeescript
@delegate 'click', '.like-button', @like
@delegate 'click', '.close-button', @skip
```

`delegate` registers the handler at the topmost DOM element of the view (`@el`) and catches events from nested elements using event bubbling. You can specify an optional selector to target nested elements.

In addition, `delegate` automatically binds the handler to the view object, so `@`/`this` points to the view. This means `delegate` creates a wrapper function which acts as the handler. As a consequence, it’s currently impossible to unbind a specific handler. Please use `@$el.off` directly to unbind all handlers of an event type for a selector:

```coffeescript
@$el.off 'click', '.like-button'
@$el.off 'click', '.close'
```

## Events catalog

Events that start with `!` immediately do something.

* `beforeControllerDispose` — emitted before current controller is disposed.
* `dispatcher:dispatch`
* `!adjustTitle`
* `!composer:retrieve`
* `!composer:compose`
* `!region:register`
* `!region:unregister`
* `!router:changeURL`
* `!router:route`
* `!router:routeByName`
* `!router:match`

![Dance](http://s3.amazonaws.com/imgly_production/3362020/original.jpg)
