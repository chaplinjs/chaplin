
define(['underscore', 'backbone', 'chaplin/lib/support'], function(_, Backbone, support) {
  'use strict';
  var descriptorsSupported;
  descriptorsSupported = support.propertyDescriptors;
  return function(options) {
    var defineProperty, mediator, privateUser, readonly, readonlyDescriptor;
    if (options == null) options = {};
    _(options).defaults({
      createUserProperty: false
    });
    defineProperty = function(prop, descriptor) {
      if (!descriptorsSupported) return;
      return Object.defineProperty(mediator, prop, descriptor);
    };
    readonlyDescriptor = {
      writable: false,
      enumerable: true,
      configurable: false
    };
    readonly = function() {
      var prop, _i, _len, _results;
      if (!descriptorsSupported) return;
      _results = [];
      for (_i = 0, _len = arguments.length; _i < _len; _i++) {
        prop = arguments[_i];
        _results.push(defineProperty(prop, readonlyDescriptor));
      }
      return _results;
    };
    mediator = {};
    mediator.subscribe = mediator.on = Backbone.Events.on;
    mediator.unsubscribe = mediator.off = Backbone.Events.off;
    mediator.publish = mediator.trigger = Backbone.Events.trigger;
    mediator._callbacks = null;
    readonly('subscribe', 'unsubscribe', 'publish');
    if (options.createUserProperty) {
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
    }
    return mediator;
  };
});
