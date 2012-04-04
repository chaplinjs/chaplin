var __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['mediator', 'controllers/controller', 'controllers/application_controller'], function(mediator, Controller, ApplicationController) {
  'use strict';  return describe('ApplicationController', function() {
    var TestController, actionCalled, applicationController, disposeCalled, freshParams, historyURLCalled, initializeCalled, params, paramsId, passedParams, resetFlags, route;
    applicationController = void 0;
    initializeCalled = actionCalled = historyURLCalled = disposeCalled = void 0;
    params = passedParams = void 0;
    paramsId = 0;
    resetFlags = function() {
      return initializeCalled = actionCalled = historyURLCalled = disposeCalled = false;
    };
    freshParams = function() {
      params = {
        changeURL: false,
        id: paramsId++
      };
      return passedParams = void 0;
    };
    route = {
      controller: 'test',
      action: 'show'
    };
    mediator.unsubscribe();
    TestController = (function(_super) {

      __extends(TestController, _super);

      function TestController() {
        TestController.__super__.constructor.apply(this, arguments);
      }

      TestController.prototype.historyURL = function(params) {
        historyURLCalled = true;
        return 'test/' + (params.id || '');
      };

      TestController.prototype.initialize = function() {
        TestController.__super__.initialize.apply(this, arguments);
        return initializeCalled = true;
      };

      TestController.prototype.show = function(params) {
        actionCalled = true;
        return passedParams = params;
      };

      TestController.prototype.dispose = function() {
        disposeCalled = true;
        return TestController.__super__.dispose.apply(this, arguments);
      };

      return TestController;

    })(Controller);
    define('controllers/test_controller', function(Controller) {
      return TestController;
    });
    beforeEach(function() {
      resetFlags();
      return freshParams();
    });
    it('should initialize', function() {
      return applicationController = new ApplicationController();
    });
    it('should dispatch routes to controller actions', function() {
      mediator.publish('matchRoute', route, params);
      expect(initializeCalled).toBe(true);
      expect(actionCalled).toBe(true);
      expect(historyURLCalled).toBe(true);
      return expect(passedParams).toBe(params);
    });
    it('should start a controller anyway when forced', function() {
      mediator.publish('matchRoute', route, params);
      resetFlags();
      params.forceStartup = true;
      mediator.publish('matchRoute', route, params);
      expect(initializeCalled).toBe(true);
      expect(actionCalled).toBe(true);
      expect(historyURLCalled).toBe(true);
      return expect(passedParams).toBe(params);
    });
    it('should dispose old controllers', function() {
      var controller, handler;
      controller = void 0;
      handler = function(passedController) {
        return controller = passedController;
      };
      mediator.subscribe('beforeControllerDispose', handler);
      return mediator.publish('matchRoute', route, params);
    });
    it('should save the current controller, action and params', function() {
      var c;
      mediator.publish('matchRoute', route, params);
      c = applicationController;
      expect(c.previousControllerName).toBe('test');
      expect(c.currentControllerName).toBe('test');
      expect(c.currentController instanceof TestController).toBe(true);
      expect(c.currentAction).toBe('show');
      expect(c.currentParams).toBe(params);
      return expect(c.url).toBe("test/" + params.id);
    });
    return it('should publish startupController events', function() {
      var event, handler;
      event = void 0;
      handler = function(passedEvent) {
        return event = passedEvent;
      };
      mediator.subscribe('startupController', handler);
      mediator.publish('matchRoute', route, params);
      mediator.unsubscribe('startupController', handler);
      expect(typeof event).toBe('object');
      expect(event.controller instanceof TestController).toBe(true);
      expect(event.controllerName).toBe('test');
      expect(event.params).toBe(params);
      return expect(event.previousControllerName).toBe('test');
    });
  });
});
