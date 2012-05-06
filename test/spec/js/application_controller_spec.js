var __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['mediator', 'chaplin/controllers/controller', 'chaplin/controllers/application_controller'], function(mediator, Controller, ApplicationController) {
  'use strict';  return describe('ApplicationController', function() {
    var TestController, applicationController, freshParams, params, paramsId, route;
    applicationController = params = null;
    paramsId = 0;
    route = {
      controller: 'test',
      action: 'show'
    };
    freshParams = function() {
      return params = {
        changeURL: false,
        id: paramsId++
      };
    };
    TestController = (function(_super) {

      __extends(TestController, _super);

      function TestController() {
        TestController.__super__.constructor.apply(this, arguments);
      }

      TestController.prototype.historyURL = function(params) {
        return 'test/' + (params.id || '');
      };

      TestController.prototype.initialize = function(params, oldControllerName) {
        return TestController.__super__.initialize.apply(this, arguments);
      };

      TestController.prototype.show = function(params, oldControllerName) {};

      TestController.prototype.dispose = function(params, newControllerName) {
        return TestController.__super__.dispose.apply(this, arguments);
      };

      return TestController;

    })(Controller);
    define('controllers/test_controller', function(Controller) {
      return TestController;
    });
    beforeEach(function() {
      return freshParams();
    });
    it('should initialize', function() {
      return applicationController = new ApplicationController();
    });
    it('should dispatch routes to controller actions', function() {
      var action, historyURL, initialize, proto;
      proto = TestController.prototype;
      historyURL = spyOn(proto, 'historyURL').andCallThrough();
      initialize = spyOn(proto, 'initialize').andCallThrough();
      action = spyOn(proto, 'show').andCallThrough();
      mediator.publish('matchRoute', route, params);
      expect(initialize).toHaveBeenCalledWith(params, null);
      expect(action).toHaveBeenCalledWith(params, null);
      return expect(historyURL).toHaveBeenCalledWith(params);
    });
    it('should start a controller anyway when forced', function() {
      var action, historyURL, initialize, proto;
      mediator.publish('matchRoute', route, params);
      proto = TestController.prototype;
      historyURL = spyOn(proto, 'historyURL').andCallThrough();
      initialize = spyOn(proto, 'initialize').andCallThrough();
      action = spyOn(proto, 'show').andCallThrough();
      params.forceStartup = true;
      mediator.publish('matchRoute', route, params);
      expect(initialize).toHaveBeenCalledWith(params, 'test');
      expect(initialize.callCount).toBe(1);
      expect(action).toHaveBeenCalledWith(params, 'test');
      expect(action.callCount).toBe(1);
      expect(historyURL).toHaveBeenCalledWith(params);
      return expect(historyURL.callCount).toBe(1);
    });
    it('should save the controller, action, params and url', function() {
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
    it('should dispose inactive controllers and fire beforeControllerDispose events', function() {
      var beforeControllerDispose, dispose, passedController;
      dispose = spyOn(TestController.prototype, 'dispose').andCallThrough();
      beforeControllerDispose = jasmine.createSpy();
      mediator.subscribe('beforeControllerDispose', beforeControllerDispose);
      mediator.publish('matchRoute', route, params);
      expect(dispose).toHaveBeenCalledWith(params, 'test');
      passedController = beforeControllerDispose.mostRecentCall.args[0];
      expect(passedController instanceof TestController).toBe(true);
      expect(passedController.disposed).toBe(true);
      return mediator.unsubscribe('beforeControllerDispose', beforeControllerDispose);
    });
    it('should publish startupController events', function() {
      var passedEvent, startupController;
      startupController = jasmine.createSpy();
      mediator.subscribe('startupController', startupController);
      mediator.publish('matchRoute', route, params);
      passedEvent = startupController.mostRecentCall.args[0];
      expect(typeof passedEvent).toBe('object');
      expect(passedEvent.controller instanceof TestController).toBe(true);
      expect(passedEvent.controllerName).toBe('test');
      expect(passedEvent.params).toBe(params);
      expect(passedEvent.previousControllerName).toBe('test');
      return mediator.unsubscribe('startupController', startupController);
    });
    return it('should be disposable', function() {
      var initialize;
      expect(typeof applicationController.dispose).toBe('function');
      applicationController.dispose();
      initialize = spyOn(TestController.prototype, 'initialize');
      mediator.publish('matchRoute', route, params);
      expect(initialize).not.toHaveBeenCalled();
      expect(applicationController.disposed).toBe(true);
      if (Object.isFrozen) {
        return expect(Object.isFrozen(applicationController)).toBe(true);
      }
    });
  });
});
