var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

define(['mediator', 'lib/route', 'routes'], function(mediator, Route, registerRoutes) {
  'use strict';
  var Router;
  return Router = (function() {

    function Router() {
      this.route = __bind(this.route, this);
      this.match = __bind(this.match, this);      registerRoutes(this.match);
      Backbone.history.start({
        pushState: true
      });
    }

    Router.prototype.match = function(pattern, target, options) {
      var route;
      if (options == null) options = {};
      Backbone.history || (Backbone.history = new Backbone.History);
      route = new Route(pattern, target, options);
      return Backbone.history.route(route, route.handler);
    };

    Router.prototype.route = function(path) {
      var handler, _i, _len, _ref;
      path = path.replace(/^(\/#|\/)/, '');
      _ref = Backbone.history.handlers;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        handler = _ref[_i];
        if (handler.route.test(path)) {
          handler.callback(path, {
            changeURL: true
          });
          return true;
        }
      }
      return false;
    };

    Router.prototype.changeURL = function(url) {
      return Backbone.history.navigate(url, {
        trigger: false
      });
    };

    return Router;

  })();
});
