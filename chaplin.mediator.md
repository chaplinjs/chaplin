---
layout: default
title: Chaplin.mediator
module_path: src/chaplin/mediator.coffee
Chaplin: mediator
---

It is one of the basic goals of Chaplin to enforce module encapsulation and independence and to direct communication through controlled channels. Chaplin’s `mediator` object is the enabler of this controlled communication. It implements the [Publish/Subscribe](http://en.wikipedia.org/wiki/Publish/subscribe) (pub/sub) pattern to ensure loose coupling of application modules, while still allowing for ease of information exchange. Instead of making direct use of other parts of the application, modules communicate by events, similar to how changes in the DOM are communicated to client-side code. Modules can listen for and react to events, but also publish events of their own to give other modules the chance to react. There are only three basic methods for this application-wide communication: `subscribe`, `unsubscribe` and `publish`.

**Note:** If you want to give local pub/sub functionality to a class, take a look at the [EventBroker](./chaplin.event_broker.html).

<h2 id="methods">Methods</h2>

<h3 class="module-member" id="subscribe">subscribe(event, handler, [context])</h3>

A wrapper for `Backbone.Events.on`. See Backbone [documentation](http://backbonejs.org/#Events-on) for more details.

<h3 class="module-member" id="unsubscribe">unsubscribe([event], [handler], [context])</h3>

A wrapper for `Backbone.Events.off`. See Backbone [documentation](http://backbonejs.org/#Events-off) for more details.

<h3 class="module-member" id="publish">publish(event, [*args])</h3>

A wrapper for `Backbone.Events.trigger`. See Backbone [documentation](http://backbonejs.org/#Events-trigger) for more details.

## Request-response methods

Since Chaplin 0.11, Chaplin uses
[request-response](http://en.wikipedia.org/wiki/Request-response)
strategy for communication between application parts.

Think of it as events, but with only one allowed handler which is at the
same time required.

<h3 class="module-member" id="setHandler">setHandler(handlerName, handler)</h3>

Sets a handler function for particular `handlerName`.

<h3 class="module-member" id="execute">execute(handlerName, [*args])</h3>

Executes a handler function from particular `handlerName`. If the handler
is not present, an error will be thrown.

## Usage

In any module that needs to communicate with other modules, access to the application-wide pub/sub system can be gained by requiring `Chaplin` as a dependency. The mediator object is then available as `Chaplin.mediator`.

```coffeescript
define ['chaplin', 'otherdependency'], (Chaplin, OtherDependency) ->
```

```javascript
define(['chaplin', 'otherdependency'], function(Chaplin, OtherDependency) {})
```

For example, if you have a session controller for logging in users, it will tell the mediator that the login occurred:

```coffeescript
Chaplin.mediator.publish 'login', user
```

```javascript
Chaplin.mediator.publish('login', user);
```

The mediator will propagate this event to any module that was subscribed to the `'login'` event, as in this example:

```coffeescript
Chaplin.mediator.subscribe 'login', @doSomething
```

```javascript
Chaplin.mediator.subscribe('login', this.doSomething);
```

Finally, if this module needs to stop listening for the login event, it can simply unsubscribe at any time:

```coffeescript
Chaplin.mediator.unsubscribe 'login', @doSomething
```

```javascript
Chaplin.mediator.unsubscribe('login', this.doSomething);
```

To add some property on mediator, it is suggested to do it in `Application#initMediator`, when mediator is getting sealed:

```coffeescript
class Application extends Chaplin.Application
  initMediator: ->
    Chaplin.mediator.prop = {hello: 'world'}
    super
```

```javascript
var Application = Chaplin.Application.extend({
  initMediator: function() {
    Chaplin.mediator.prop = {hello: 'world'};
    this.constructor.__super__.initMediator.call(this);
  }
})
```
