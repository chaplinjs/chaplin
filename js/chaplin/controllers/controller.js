var __hasProp = Object.prototype.hasOwnProperty;

define(['underscore', 'chaplin/lib/subscriber'], function(_, Subscriber) {
  'use strict';
  var Controller;
  return Controller = (function() {

    _(Controller.prototype).extend(Subscriber);

    Controller.prototype.view = null;

    Controller.prototype.currentId = null;

    function Controller() {
      this.initialize.apply(this, arguments);
    }

    Controller.prototype.initialize = function() {};

    Controller.prototype.disposed = false;

    Controller.prototype.dispose = function() {
      /*console.debug 'Controller#dispose', this, 'disposed?', @disposed
      */
      var obj, prop, properties, _i, _len;
      if (this.disposed) return;
      for (prop in this) {
        if (!__hasProp.call(this, prop)) continue;
        obj = this[prop];
        if (obj && typeof obj.dispose === 'function') {
          obj.dispose();
          delete this[prop];
        }
      }
      this.unsubscribeAllEvents();
      properties = ['currentId'];
      for (_i = 0, _len = properties.length; _i < _len; _i++) {
        prop = properties[_i];
        delete this[prop];
      }
      this.disposed = true;
      return typeof Object.freeze === "function" ? Object.freeze(this) : void 0;
    };

    return Controller;

  })();
});
