
define(['mediator'], function(mediator) {
  'use strict';
  var Subscriber;
  Subscriber = {
    subscribeEvent: function(type, handler) {
      if (typeof type !== 'string') {
        throw new TypeError('Subscriber#subscribeEvent: ' + 'type argument must be string');
      }
      if (typeof handler !== 'function') {
        throw new TypeError('Subscriber#subscribeEvent: ' + 'handler argument must be function');
      }
      mediator.unsubscribe(type, handler, this);
      return mediator.subscribe(type, handler, this);
    },
    unsubscribeEvent: function(type, handler) {
      if (typeof type !== 'string') {
        throw new TypeError('Subscriber#unsubscribeEvent: ' + 'type argument must be string');
      }
      if (typeof handler !== 'function') {
        throw new TypeError('Subscriber#unsubscribeEvent: ' + 'handler argument must be function');
      }
      return mediator.unsubscribe(type, handler);
    },
    unsubscribeAllEvents: function() {
      return mediator.unsubscribe(null, null, this);
    }
  };
  if (typeof Object.freeze === "function") Object.freeze(Subscriber);
  return Subscriber;
});
