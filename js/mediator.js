
define(function() {
  'use strict';
  var descriptorsSupported, mediator, privateUser, readonlyDescriptor;
  mediator = {};
  readonlyDescriptor = {
    writable: false,
    configurable: false,
    enumerable: true
  };
  descriptorsSupported = (function() {
    if (!(Object.defineProperty && Object.defineProperties)) return false;
    try {
      Object.defineProperty({}, 'foo', {
        value: 'bar'
      });
      return true;
    } catch (error) {
      return false;
    }
  })();
  mediator.user = null;
  if (descriptorsSupported) {
    privateUser = null;
    Object.defineProperty(mediator, 'user', {
      get: function() {
        return privateUser;
      },
      set: function() {
        throw new Error('mediator.user is not writable. Use mediator.setUser.');
      },
      enumerable: true,
      configurable: false
    });
  }
  mediator.setUser = function(user) {
    if (descriptorsSupported) {
      return privateUser = user;
    } else {
      return mediator.user = user;
    }
  };
  if (descriptorsSupported) {
    Object.defineProperty(mediator, 'setUser', readonlyDescriptor);
  }
  mediator.router = null;
  _(mediator).defaults(Backbone.Events);
  mediator._callbacks = null;
  mediator.subscribe = mediator.on = Backbone.Events.on;
  mediator.unsubscribe = mediator.off = Backbone.Events.off;
  mediator.publish = mediator.trigger = Backbone.Events.trigger;
  if (descriptorsSupported) {
    Object.defineProperties(mediator, {
      subscribe: readonlyDescriptor,
      unsubscribe: readonlyDescriptor,
      publish: readonlyDescriptor
    });
  }
  if (typeof Object.seal === "function") Object.seal(mediator);
  return mediator;
});
