# [Chaplin.EventBroker](../src/chaplin/lib/event_broker.coffee)

The EventBroker offer an interface to interact with [Chaplin.mediator](./chaplin.mediator.md).

## Methods of `Chaplin.EventBroker`

### publishEvent(event, arguments...)
Publish the global `event` with `arguments`.

### subscribeEvent(event, handler)
Unsubcribe the `handler` to the `event` (if it exists) before subscribing it. It is like `Chaplin.mediator.subscribe` except it cannot subscribe twice.

### unsubscribeEvent(event, handler)
Unsubcribe the `handler` to the `event`. It is like `Chaplin.mediator.unsubscribe`.

### unsubscribeAllEvents()
Unsubcribe all handlers for all events.

## Usage

To give a Class the Pub/Sub pattern, you just need to make it extend the Chaplin.EventBroker: `_(@prototype).extend EventBroker` (coffee) or `_(this.prototype).extend(EventBroker)` (js).
