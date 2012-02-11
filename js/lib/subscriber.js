var __hasProp = Object.prototype.hasOwnProperty;

define(['mediator'], function(mediator) {
  'use strict';
  var Subscriber;
  return Subscriber = {
    globalSubscriptions: null,
    subscribeEvent: function(type, handler) {
      var handlers, _base;
      this.globalSubscriptions || (this.globalSubscriptions = {});
      handlers = (_base = this.globalSubscriptions)[type] || (_base[type] = []);
      if (_(handlers).include(handler)) return;
      handlers.push(handler);
      return mediator.subscribe(type, handler, this);
    },
    unsubscribeEvent: function(type, handler) {
      var handlers, index;
      if (!this.globalSubscriptions) return;
      handlers = this.globalSubscriptions[type];
      if (handlers) {
        index = _(handlers).indexOf(handler);
        if (index > -1) handlers.splice(index, 1);
        if (handlers.length === 0) delete this.globalSubscriptions[type];
      }
      return mediator.unsubscribe(type, handler);
    },
    unsubscribeAllEvents: function() {
      var handler, handlers, type, _i, _len, _ref;
      if (!this.globalSubscriptions) return;
      _ref = this.globalSubscriptions;
      for (type in _ref) {
        if (!__hasProp.call(_ref, type)) continue;
        handlers = _ref[type];
        for (_i = 0, _len = handlers.length; _i < _len; _i++) {
          handler = handlers[_i];
          mediator.unsubscribe(type, handler);
        }
      }
      return this.globalSubscriptions = null;
    }
  };
});
