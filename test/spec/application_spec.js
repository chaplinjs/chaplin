define(
    ['mediator', 'application', 'lib/router', 'controllers/session_controller', 'controllers/application_controller'],
    function (mediator, Application, Router, SessionController, ApplicationController)
{
  'use strict';

  describe('Application', function () {

    it('should be a simple object', function () {
      expect(typeof Application).toEqual('object');
    });

    it('should initialize', function () {
      expect(typeof Application.initialize).toBe('function');
      Application.initialize();
    });

    it('should create a session controller', function () {
      expect(Application.sessionController instanceof SessionController)
        .toEqual(true);
    });

    it('should create an application controller', function () {
      expect(Application.applicationController instanceof ApplicationController)
        .toEqual(true);
    });

    it('should create a router', function () {
      expect(mediator.router instanceof Router).toEqual(true);
    });

    it('should create a readonly router', function () {
      if (!Object.defineProperty) return;

      expect(function () {
        mediator.router = 'foo';
      }).toThrow();

      var desc = Object.getOwnPropertyDescriptor(mediator, 'router');
      expect(desc.writable).toBe(false);
    });

    it('should start Backbone.history', function () {
      expect(Backbone.History.started).toBe(true);
    });

    it('should be frozen', function () {
      if (!Object.isFrozen) return;
      expect(Object.isFrozen(Application)).toBe(true);
    });

  });
});