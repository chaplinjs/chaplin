
define(['mediator'], function(mediator) {
  'use strict';
  var Subscriber;
  Subscriber = {
    _globalSubscriptions: null,
    subscribeEvent: function(type, handler) {
      var handlers, _base;
      if (typeof type !== 'string') {
        throw new TypeError('Subscriber#subscribeEvent: type argument must be string');
      }
      if (typeof handler !== 'function') {
        throw new TypeError('Subscriber#subscribeEvent: handler argument must be function');
      }
      this._globalSubscriptions || (this._globalSubscriptions = {});
      handlers = (_base = this._globalSubscriptions)[type] || (_base[type] = []);
      if (_(handlers).include(handler)) return;
      handlers.push(handler);
      return mediator.subscribe(type, handler, this);
    },
    unsubscribeEvent: function(type, handler) {
      var handlers, index;
      if (typeof type !== 'string') {
        throw new TypeError('Subscriber#unsubscribeEvent: type argument must be string');
      }
      if (typeof handler !== 'function') {
        throw new TypeError('Subscriber#unsubscribeEvent: handler argument must be function');
      }
      if (!this._globalSubscriptions) return;
      handlers = this._globalSubscriptions[type];
      if (handlers) {
        index = _(handlers).indexOf(handler);
        if (index > -1) handlers.splice(index, 1);
        if (handlers.length === 0) delete this._globalSubscriptions[type];
      }
      return mediator.unsubscribe(type, handler);
    },
    unsubscribeAllEvents: function() {
      this._globalSubscriptions = null;
      return mediator.unsubscribe(null, null, this);
    }
  };
  if (typeof Object.freeze === "function") Object.freeze(Subscriber);
  return Subscriber;
});
