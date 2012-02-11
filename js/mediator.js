
define(function() {
  'use strict';
  var desc, mediator;
  mediator = {};
  mediator.user = null;
  mediator.router = null;
  _(mediator).defaults(Backbone.Events);
  mediator._callbacks = null;
  mediator.subscribe = Backbone.Events.on;
  mediator.unsubscribe = Backbone.Events.off;
  mediator.publish = Backbone.Events.trigger;
  if (Object.defineProperties) {
    desc = {
      writable: false
    };
    Object.defineProperties(mediator, {
      subscribe: desc,
      unsubscribe: desc,
      publish: desc
    });
  }
  if (typeof Object.seal === "function") Object.seal(mediator);
  return mediator;
});
