var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

define(['mediator', 'lib/route'], function(mediator, Route) {
  'use strict';
  var Router;
  return Router = (function() {

    function Router() {
      this.follow = __bind(this.follow, this);      this.registerRoutes();
      this.startHistory();
    }

    Router.prototype.registerRoutes = function() {
      this.match('', 'likes#index');
      return this.match('likes/:id', 'likes#show');
    };

    Router.prototype.startHistory = function() {
      return Backbone.history.start({
        pushState: true
      });
    };

    Router.prototype.match = function(expression, target, options) {
      var route;
      if (options == null) options = {};
      Backbone.history || (Backbone.history = new Backbone.History);
      route = new Route(expression, target, options);
      return Backbone.history.route(route, route.handler);
    };

    Router.prototype.follow = function(path, params) {
      var handler, _i, _len, _ref;
      if (params == null) params = {};
      console.debug('Router#follow', path, params);
      path = path.replace(/^(\/#|\/)/, '');
      _ref = Backbone.history.handlers;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        handler = _ref[_i];
        if (handler.route.test(path)) {
          handler.callback(path, params);
          return true;
        }
      }
      return false;
    };

    Router.prototype.navigate = function(url) {
      return Backbone.history.navigate(url, {
        trigger: false
      });
    };

    return Router;

  })();
});
