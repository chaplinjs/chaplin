---
layout: default
title: Chaplin.EventBroker
module_path: src/chaplin/lib/event_broker.coffee
Chaplin: EventBroker
---

The `EventBroker` offers an interface to interact with [Chaplin.mediator](./chaplin.mediator.html), meant to be used as a mixin.

<h2 id="methods">Methods</h2>

<h3 class="module-member" id="publishEvent">publishEvent(event, arguments...)</h3>
Publishes `event` globablly, passing `arguments` along for interested subscribers.

<h3 class="module-member" id="subscribeEvent">subscribeEvent(event, handler)</h3>
Subscribes the `handler` to the given `event`. If `handler` already subscribed to `event`, it will be removed as a subscriber and added afresh. This function is like `Chaplin.mediator.subscribe` except it cannot subscribe twice.

<h3 class="module-member" id="unsubscribeEvent">unsubscribeEvent(event, handler)</h3>
Unsubcribe the `handler` from the `event`. This functions like `Chaplin.mediator.unsubscribe`.

<h3 class="module-member" id="unsubscribeAllEvents">unsubscribeAllEvents()</h3>
Unsubcribe from any subscriptions made through this objects `subscribeEvent` method.

## Usage

To give a class these pub/sub capabilities, you just need to make it extend `Chaplin.EventBroker`: <span class="coffeescript">`_.extend @prototype, EventBroker`</span> <span class="javascript">`_.extend(this.prototype, EventBroker)`</span>.
