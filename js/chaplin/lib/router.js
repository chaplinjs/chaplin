var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

define(['underscore', 'backbone', 'mediator', 'chaplin/lib/subscriber', 'chaplin/lib/route'], function(_, Backbone, mediator, Subscriber, Route) {
  'use strict';
  var Router;
  return Router = (function() {

    _(Router.prototype).extend(Subscriber);

    function Router(options) {
      this.options = options != null ? options : {};
      this.route = __bind(this.route, this);
      this.match = __bind(this.match, this);
      /*console.debug 'Router#constructor'
      */
      this.subscribeEvent('!router:route', this.routeHandler);
      this.subscribeEvent('!router:changeURL', this.changeURLHandler);
      this.createHistory();
    }

    Router.prototype.createHistory = function() {
      return Backbone.history || (Backbone.history = new Backbone.History());
    };

    Router.prototype.startHistory = function() {
      var pushState, _ref;
      pushState = (_ref = this.options.pushState) != null ? _ref : true;
      return Backbone.history.start({
        pushState: pushState
      });
    };

    Router.prototype.stopHistory = function() {
      return Backbone.history.stop();
    };

    Router.prototype.match = function(pattern, target, options) {
      var route;
      if (options == null) options = {};
      route = new Route(pattern, target, options);
      return Backbone.history.route(route, route.handler);
    };

    Router.prototype.route = function(path) {
      /*console.debug 'Router#route', path
      */
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

    Router.prototype.routeHandler = function(path, callback) {
      var routed;
      routed = this.route(path);
      return typeof callback === "function" ? callback(routed) : void 0;
    };

    Router.prototype.changeURL = function(url) {
      /*console.debug 'Router#changeURL', url
      */      return Backbone.history.navigate(url, {
        trigger: false
      });
    };

    Router.prototype.changeURLHandler = function(url) {
      return this.changeURL(url);
    };

    Router.prototype.disposed = false;

    Router.prototype.dispose = function() {
      /*console.debug 'Router#dispose'
      */      if (this.disposed) return;
      this.stopHistory();
      delete Backbone.history;
      this.unsubscribeAllEvents();
      this.disposed = true;
      return typeof Object.freeze === "function" ? Object.freeze(this) : void 0;
    };

    return Router;

  })();
});
