
define(['mediator', 'chaplin/application', 'chaplin/lib/router', 'chaplin/controllers/application_controller', 'chaplin/views/application_view'], function(mediator, Application, Router, ApplicationController, ApplicationView) {
  'use strict';  return describe('Application', function() {
    var application;
    application = new Application();
    it('should be a simple object', function() {
      expect(typeof application).toEqual('object');
      return expect(application instanceof Application).toBe(true);
    });
    it('should initialize', function() {
      expect(typeof application.initialize).toBe('function');
      return application.initialize();
    });
    it('should create an application controller', function() {
      return expect(application.applicationController instanceof ApplicationController).toEqual(true);
    });
    it('should create an application view', function() {
      return expect(application.applicationView instanceof ApplicationView).toEqual(true);
    });
    it('should create a router', function() {
      var passedMatch, routes, routesCalled;
      passedMatch = void 0;
      routesCalled = false;
      routes = function(match) {
        routesCalled = true;
        return passedMatch = match;
      };
      expect(typeof application.initRouter).toBe('function');
      application.initRouter(routes);
      expect(application.router instanceof Router).toEqual(true);
      expect(routesCalled).toBe(true);
      return expect(typeof passedMatch).toBe('function');
    });
    it('should start Backbone.history', function() {
      return expect(Backbone.History.started).toBe(true);
    });
    return it('should be disposable', function() {
      expect(typeof application.dispose).toBe('function');
      application.dispose();
      expect(application.applicationController).toBe(null);
      expect(application.applicationView).toBe(null);
      expect(application.router).toBe(null);
      expect(application.disposed).toBe(true);
      if (Object.isFrozen) return expect(Object.isFrozen(application)).toBe(true);
    });
  });
});
