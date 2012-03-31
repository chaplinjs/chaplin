
define(['lib/support'], function(support) {
  'use strict';
  var defineProperty, descriptorsSupported, mediator, privateUser, readonly, readonlyDescriptor;
  mediator = {};
  descriptorsSupported = support.propertyDescriptors;
  readonlyDescriptor = {
    writable: false,
    configurable: false,
    enumerable: true
  };
  defineProperty = function(obj, prop, descriptor) {
    if (descriptorsSupported) return Object.defineProperty(obj, prop, descriptor);
  };
  readonly = function(obj, prop) {
    return defineProperty(obj, prop, readonlyDescriptor);
  };
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
  readonly(mediator, 'setUser');
  mediator.router = null;
  mediator.setRouter = function(router) {
    if (mediator.router) throw new Error('Router already set');
    mediator.router = router;
    return readonly(mediator, 'router');
  };
  readonly(mediator, 'setRouter');
  _(mediator).extend(Backbone.Events);
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
