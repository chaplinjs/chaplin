---
layout: default
title: Chaplin.EventBroker
module_path: src/chaplin/lib/event_broker.coffee
---

The EventBroker offer an interface to interact with [Chaplin.mediator](./chaplin.mediator.html).

<h2 id="methods">Methods</h2>

<h3 class="module-member" id="publishEvent">publishEvent(event, arguments...)</h3>
Publish the global `event` with `arguments`.

<h3 class="module-member" id="subscribeEvent">subscribeEvent(event, handler)</h3>
Unsubcribe the `handler` to the `event` (if it exists) before subscribing it. It is like `Chaplin.mediator.subscribe` except it cannot subscribe twice.

<h3 class="module-member" id="unsubscribeEvent">unsubscribeEvent(event, handler)</h3>
Unsubcribe the `handler` to the `event`. It is like `Chaplin.mediator.unsubscribe`.

<h3 class="module-member" id="unsubscribeAllEvents">unsubscribeAllEvents()</h3>
Unsubcribe all handlers for all events.

## Usage

To give a Class the Pub/Sub pattern, you just need to make it extend the
Chaplin.EventBroker: <span class="coffeescript">`_.extend @prototype,
EventBroker`</span> <span class="javascript">`_.extend(this.prototype,
EventBroker)`</span>.
