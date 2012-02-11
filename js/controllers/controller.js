var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

define(['lib/subscriber'], function(Subscriber) {
  'use strict';
  var Controller;
  return Controller = (function() {

    _(Controller.prototype).defaults(Subscriber);

    Controller.prototype.model = null;

    Controller.prototype.collection = null;

    Controller.prototype.view = null;

    Controller.prototype.currentId = null;

    function Controller() {
      this.dispose = __bind(this.dispose, this);      this.initialize();
    }

    Controller.prototype.initialize = function() {};

    Controller.prototype.startup = function() {};

    Controller.prototype.disposed = false;

    Controller.prototype.dispose = function() {
      var prop, properties, _i, _len;
      if (this.disposed) return;
      if (this.model) {
        this.model.dispose();
      } else if (this.collection) {
        this.collection.dispose();
      } else if (this.view) {
        this.view.dispose();
      }
      this.unsubscribeAllEvents();
      properties = 'model collection view currentId'.split(' ');
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
