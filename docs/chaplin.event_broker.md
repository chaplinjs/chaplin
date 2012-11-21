# Chaplin.EventBroker

The EventBroker offer an interface to interact with [Chaplin.mediator](./chaplin.mediator.md). As of Backbone 0.9.2, the broker just serves the purpose that a handler cannot be registered twice for the same event.

## Methods of `Chaplin.EventBroker`

### publishEvent(event, arguments...)
Publish the global `event` with `arguments`.


### subscribeEvent(event, handler)
Unsubcribe the `handler` to the `event` (if it exists) before subscribing it. It is like `Chaplin.mediator.subscribe` except it cannot subscribe twice.


### unsubscribeEvent(event, handler)
Unsubcribe the `handler` to the `event`. It is like `Chaplin.mediator.unsubscribe`.


### subscribeAllEvents()
Unsubcribe all handlers for all events.

## Usage

To give a Class the Pub/Sub patter, you just need to make it extend the Chaplin.EventBroker: `_(@prototype).extend EventBroker` (coffee) or `_(this.prototype).extend(EventBroker)` (js).

## [Code](https://github.com/chaplinjs/chaplin/blob/master/src/chaplin/lib/event_broker.coffee)
