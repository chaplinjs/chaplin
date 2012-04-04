
define(['mediator', 'application', 'lib/router', 'controllers/session_controller', 'controllers/application_controller'], function(mediator, Application, Router, SessionController, ApplicationController) {
  'use strict';  return describe('Application', function() {
    it('should be a simple object', function() {
      return expect(typeof Application).toEqual('object');
    });
    it('should initialize', function() {
      expect(typeof Application.initialize).toBe('function');
      return Application.initialize();
    });
    it('should create a session controller', function() {
      return expect(Application.sessionController instanceof SessionController).toEqual(true);
    });
    it('should create an application controller', function() {
      return expect(Application.applicationController instanceof ApplicationController).toEqual(true);
    });
    it('should create a router on the mediator', function() {
      return expect(mediator.router instanceof Router).toEqual(true);
    });
    it('should start Backbone.history', function() {
      return expect(Backbone.History.started).toBe(true);
    });
    return it('should be frozen', function() {
      if (!Object.isFrozen) return;
      return expect(Object.isFrozen(Application)).toBe(true);
    });
  });
});
