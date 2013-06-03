---
layout: default
title: Chaplin.mediator
module_path: src/chaplin/mediator.coffee
---

As all modules are encapsulated and independent from each other, we need a way to make them communicate. That's the Mediator's role. The Mediator implement the [Publish/Subscribe](http://en.wikipedia.org/wiki/Publish/subscribe) (Pub/Sub) pattern to ensure loose coupling of application modules. That’s just a simple object which has per default three methods for global Publish/Subscribe: `subscribe`, `unsubscribe` and `publish`.

To inform other modules that something happened, a module doesn’t send messages directly (i.e. calling methods of specific objects). Instead, it publishes a message to the mediator without having to know who is listening. Other application modules might subscribe to these messages and react upon them.

**Note:** If you want to give Pub/Sub functionality to a Class, also look at the [EventBroker](./chaplin.event_broker.html).


<h2 id="methods">Methods</h2>

<h3 class="module-member" id="subscribe">subscribe(event, handler, [context])</h3>

A wrapper for `Backbone.Events.on`. See Backbone [documentation](http://backbonejs.org/#Events-on) for more details.

<h3 class="module-member" id="unsubscribe">unsubscribe([event], [handler], [context])</h3>

A wrapper for `Backbone.Events.off`. See Backbone [documentation](http://backbonejs.org/#Events-off) for more details.

<h3 class="module-member" id="publish">publish(event, [*args])</h3>

A wrapper for `Backbone.Events.trigger`. See Backbone [documentation](http://backbonejs.org/#Events-trigger) for more details.

## Usage

Any module that need to publish or subscrib to messages to/from other modules must require `Chaplin` as a dependency.

```coffeescript
define ['chaplin', 'otherdependency'], (Chaplin, OtherDependency) ->
```

```javascript
define(['chaplin', 'otherdependency'], function(Chaplin, OtherDependency) {})
```

For example, if you have a session_controller that logs the user in, it will tell the mediator (which will tell it to interested modules) that the login happened by doing:

```coffeescript
Chaplin.mediator.publish 'login', user
```

```javascript
Chaplin.mediator.publish('login', user);
```

Any module that is interested to know about the user login will subscribe to it by doing:

```coffeescript
Chaplin.mediator.subscribe 'login', @doSomething
```

```javascript
Chaplin.mediator.subscribe('login', this.doSomething);
```

Finally, if this module needs to stop listening on the login event, it can just unsubscribe by doing:

```coffeescript
Chaplin.mediator.unsubscribe 'login', @doSomething
```

```javascript
Chaplin.mediator.unsubscribe('login', this.doSomething);
```
