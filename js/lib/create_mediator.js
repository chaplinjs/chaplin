
define(['lib/support'], function(support) {
  'use strict';
  var createMediator, descriptorsSupported;
  descriptorsSupported = support.propertyDescriptors;
  createMediator = function() {
    var defineProperty, mediator, privateRouter, privateUser, readonly;
    defineProperty = function(prop, descriptor) {
      if (!descriptorsSupported) return;
      return Object.defineProperty(mediator, prop, descriptor);
    };
    readonly = function() {
      var descriptor, prop, _i, _len, _results;
      if (!descriptorsSupported) return;
      _results = [];
      for (_i = 0, _len = arguments.length; _i < _len; _i++) {
        prop = arguments[_i];
        descriptor = Object.getOwnPropertyDescriptor(mediator, prop);
        descriptor.writable = false;
        _results.push(defineProperty(prop, descriptor));
      }
      return _results;
    };
    mediator = {};
    mediator.subscribe = mediator.on = Backbone.Events.on;
    mediator.unsubscribe = mediator.off = Backbone.Events.off;
    mediator.publish = mediator.trigger = Backbone.Events.trigger;
    mediator._callbacks = null;
    readonly('subscribe', 'unsubscribe', 'publish');
    mediator.user = null;
    privateUser = null;
    defineProperty('user', {
      get: function() {
        return privateUser;
      },
      set: function() {
        throw new Error('mediator.user is not writable directly. ' + 'Please use mediator.setUser instead.');
      },
      enumerable: true,
      configurable: false
    });
    mediator.setUser = function(user) {
      if (descriptorsSupported) {
        return privateUser = user;
      } else {
        return mediator.user = user;
      }
    };
    readonly('setUser');
    mediator.router = null;
    privateRouter = null;
    defineProperty('router', {
      get: function() {
        return privateRouter;
      },
      set: function() {
        throw new Error('mediator.router is not writable directly. ' + 'Please use mediator.setRouter instead.');
      },
      enumerable: true,
      configurable: false
    });
    mediator.setRouter = function(router) {
      if (mediator.router) {
        throw new Error('mediator.router was already set, ' + 'it can only be set once.');
      }
      if (descriptorsSupported) {
        return privateRouter = router;
      } else {
        return mediator.router = router;
      }
    };
    if (descriptorsSupported && Object.seal) Object.seal(mediator);
    return mediator;
  };
  return createMediator;
});
