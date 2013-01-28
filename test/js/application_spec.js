// Generated by CoffeeScript 1.4.0
var __hasProp = {}.hasOwnProperty;

define(['underscore', 'chaplin/mediator', 'chaplin/application', 'chaplin/lib/router', 'chaplin/dispatcher', 'chaplin/views/layout', 'chaplin/lib/event_broker'], function(_, mediator, Application, Router, Dispatcher, Layout, EventBroker) {
  'use strict';
  return describe('Application', function() {
    var app;
    app = new Application();
    it('should be a simple object', function() {
      expect(app).to.be.an('object');
      return expect(app).to.be.a(Application);
    });
    it('should mixin a EventBroker', function() {
      var name, value, _results;
      _results = [];
      for (name in EventBroker) {
        if (!__hasProp.call(EventBroker, name)) continue;
        value = EventBroker[name];
        _results.push(expect(app[name]).to.be(EventBroker[name]));
      }
      return _results;
    });
    it('should initialize', function() {
      expect(app.initialize).to.be.a('function');
      return app.initialize();
    });
    it('should create a dispatcher', function() {
      expect(app.initDispatcher).to.be.a('function');
      app.initDispatcher();
      return expect(app.dispatcher).to.be.a(Dispatcher);
    });
    it('should create a layout', function() {
      expect(app.initLayout).to.be.a('function');
      app.initLayout();
      return expect(app.layout).to.be.a(Layout);
    });
    it('should create a router', function() {
      var passedMatch, routes, routesCalled;
      passedMatch = null;
      routesCalled = false;
      routes = function(match) {
        routesCalled = true;
        return passedMatch = match;
      };
      expect(app.initRouter).to.be.a('function');
      expect(app.initRouter.length).to.be(2);
      app.initRouter(routes, {
        root: '/'
      });
      expect(app.router).to.be.a(Router);
      expect(routesCalled).to.be(true);
      return expect(passedMatch).to.be.a('function');
    });
    it('should start Backbone.history', function() {
      return expect(Backbone.History.started).to.be(true);
    });
    it('should dispose itself correctly', function() {
      var prop, _i, _len, _ref;
      expect(app.dispose).to.be.a('function');
      app.dispose();
      _ref = ['dispatcher', 'layout', 'router'];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        prop = _ref[_i];
        expect(_(app).has(prop)).to.not.be.ok();
      }
      expect(app.disposed).to.be(true);
      if (Object.isFrozen) {
        return expect(Object.isFrozen(app)).to.be(true);
      }
    });
    return it('should be extendable', function() {
      var DerivedApplication, derivedApp;
      expect(Application.extend).to.be.a('function');
      DerivedApplication = Application.extend();
      derivedApp = new DerivedApplication();
      expect(derivedApp).to.be.a(Application);
      return derivedApp.dispose();
    });
  });
});
