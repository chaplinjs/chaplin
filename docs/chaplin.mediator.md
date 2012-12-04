# Chaplin.Mediator
As all modules are encapsulated and independent from each other, we need a way to make them communicate. That's the Mediator's role. The Mediator implement the [Publish/Subscribe](http://en.wikipedia.org/wiki/Publish/subscribe) (Pub/Sub) pattern to ensure loose coupling of application modules. That’s just a simple object which has per default three methods for global Publish/Subscribe: `subscribe`, `unsubscribe` and `publish`.

To inform other modules that something happened, a module doesn’t send messages directly (i.e. calling methods of specific objects). Instead, it publishes a message to the mediator without having to know who is listening. Other application modules might subscribe to these messages and react upon them.

Note: If you want to give Pub/Sub functionality to a Class, also look at the [Subscriber](./chaplin.subscriber.md).


## Methods of `Chaplin.mediator`

<a name="subscribe"></a>

### subscribe(event, handler, [context])

A wrapper for `Backbone.Events.on`. See Backbone [documentation](http://backbonejs.org/#Events-on) for more details.

<a name="unsubscribe"></a>

### unsubscribe([event], [handler], [context])

A wrapper for `Backbone.Events.off`. See Backbone [documentation](http://backbonejs.org/#Events-off) for more details.

<a name="publish"></a>

### publish(event, [*args])

A wrapper for `Backbone.Events.trigger`. See Backbone [documentation](http://backbonejs.org/#Events-trigger) for more details.

## Usage

Any module that need to publish or subscrib to messages to/from other modules must require `Chaplin` as a dependency.

```coffeescript
define ['chaplin', 'otherdependency'], (Chaplin, OtherDependency) ->
```

For example, if you have a session_controller that login the user, it will tell the mediator (which will tell it to interested modules) that the login happened by doing:

```coffeescript
Chaplin.mediator.publish 'login', user
```

Any module that is interested to know about the user login will subscribe to it by doing:

```coffeescript
Chaplin.mediator.subscribe 'login', @doSomething
```

Finally, if this module needs to stop listening on the login event, it can just unsubscribe by doing:

```coffeescript
Chaplin.mediator.unsubscribe 'login', @doSomething
```

## [Code](https://github.com/chaplinjs/chaplin/blob/master/src/chaplin/mediator.coffee)
