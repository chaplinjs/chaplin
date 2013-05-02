# [Chaplin.mediator](../src/chaplin/mediator.coffee)
As all modules are encapsulated and independent from each other, we need a way to make them communicate. That's the Mediator's role. The Mediator implement the [Publish/Subscribe](http://en.wikipedia.org/wiki/Publish/subscribe) (Pub/Sub) pattern to ensure loose coupling of application modules. That’s just a simple object which has per default three methods for global Publish/Subscribe: `subscribe`, `unsubscribe` and `publish`.

To inform other modules that something happened, a module doesn’t send messages directly (i.e. calling methods of specific objects). Instead, it publishes a message to the mediator without having to know who is listening. Other application modules might subscribe to these messages and react upon them.

Note: If you want to give Pub/Sub functionality to a Class, also look at the [EventBroker](./chaplin.event_broker.md).


## Methods of `Chaplin.mediator`

### subscribe(event, handler, [context])

A wrapper for `Backbone.Events.on`. See Backbone [documentation](http://backbonejs.org/#Events-on) for more details.

### unsubscribe([event], [handler], [context])

A wrapper for `Backbone.Events.off`. See Backbone [documentation](http://backbonejs.org/#Events-off) for more details.

### publish(event, [*args])

A wrapper for `Backbone.Events.trigger`. See Backbone [documentation](http://backbonejs.org/#Events-trigger) for more details.

## Usage

Any module that need to publish or subscrib to messages to/from other modules must require `Chaplin` as a dependency.

```coffeescript
# CoffeeScript
define ['chaplin', 'otherdependency'], (Chaplin, OtherDependency) ->
```

```javascript
// JavaScript
define(['chaplin', 'otherdependency'], function(Chaplin, OtherDependency) {})
```

For example, if you have a session_controller that logs the user in, it will tell the mediator (which will tell it to interested modules) that the login happened by doing:

```coffeescript
# CoffeeScript
Chaplin.mediator.publish 'login', user
```

```javascript
// JavaScript
Chaplin.mediator.publish('login', user);
```

Any module that is interested to know about the user login will subscribe to it by doing:

```coffeescript
# CoffeeScript
Chaplin.mediator.subscribe 'login', @doSomething
```

```javascript
// JavaScript
Chaplin.mediator.subscribe('login', this.doSomething);
```

Finally, if this module needs to stop listening on the login event, it can just unsubscribe by doing:

```coffeescript
# CoffeeScript
Chaplin.mediator.unsubscribe 'login', @doSomething
```

```javascript
// JavaScript
Chaplin.mediator.unsubscribe('login', this.doSomething);
```
