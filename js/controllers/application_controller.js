var __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['mediator', 'lib/utils', 'lib/subscriber', 'controllers/controller', 'views/application_view', 'controllers/navigation_controller', 'controllers/sidebar_controller'], function(mediator, utils, Subscriber, Controller, ApplicationView, NavigationController, SidebarController) {
  'use strict';
  var ApplicationController;
  return ApplicationController = (function(_super) {

    __extends(ApplicationController, _super);

    function ApplicationController() {
      ApplicationController.__super__.constructor.apply(this, arguments);
    }

    _(ApplicationController.prototype).extend(Subscriber);

    ApplicationController.prototype.previousControllerName = null;

    ApplicationController.prototype.currentControllerName = null;

    ApplicationController.prototype.currentController = null;

    ApplicationController.prototype.currentAction = null;

    ApplicationController.prototype.currentParams = null;

    ApplicationController.prototype.url = null;

    ApplicationController.prototype.initialize = function() {
      this.subscribeEvent('matchRoute', this.matchRoute);
      this.subscribeEvent('!startupController', this.startupController);
      this.initApplicationView();
      return this.initCommonControllers();
    };

    ApplicationController.prototype.initApplicationView = function() {
      return this.view = new ApplicationView();
    };

    ApplicationController.prototype.initCommonControllers = function() {
      this.navigationController = new NavigationController();
      return this.sidebarController = new SidebarController();
    };

    ApplicationController.prototype.disposeCommonControllers = function() {
      this.navigationController.dispose();
      return this.sidebarController.dispose();
    };

    ApplicationController.prototype.matchRoute = function(route, params) {
      return this.startupController(route.controller, route.action, params);
    };

    ApplicationController.prototype.startupController = function(controllerName, action, params) {
      var controllerFileName, handler, isSameController;
      if (action == null) action = 'index';
      if (params == null) params = {};
      if (params.changeURL !== false) params.changeURL = true;
      if (params.forceStartup !== true) params.forceStartup = false;
      isSameController = !params.forceStartup && this.currentControllerName === controllerName && this.currentAction === action && (!this.currentParams || _(params).isEqual(this.currentParams));
      if (isSameController) return;
      controllerFileName = utils.underscorize(controllerName) + '_controller';
      handler = _(this.controllerLoaded).bind(this, controllerName, action, params);
      return require(['controllers/' + controllerFileName], handler);
    };

    ApplicationController.prototype.controllerLoaded = function(controllerName, action, params, ControllerConstructor) {
      var controller, currentController, currentControllerName;
      currentControllerName = this.currentControllerName || null;
      currentController = this.currentController || null;
      if (currentController) {
        mediator.publish('beforeControllerDispose', currentController);
        currentController.dispose(params, controllerName);
      }
      controller = new ControllerConstructor();
      controller.initialize(params, currentControllerName);
      controller[action](params, currentControllerName);
      this.previousControllerName = currentControllerName;
      this.currentControllerName = controllerName;
      this.currentController = controller;
      this.currentAction = action;
      this.currentParams = params;
      this.adjustURL(controller, params);
      return mediator.publish('startupController', {
        previousControllerName: this.previousControllerName,
        controller: this.currentController,
        controllerName: this.currentControllerName,
        params: this.currentParams
      });
    };

    ApplicationController.prototype.adjustURL = function(controller, params) {
      var url;
      if (typeof controller.historyURL === 'function') {
        url = controller.historyURL(params);
      } else if (typeof controller.historyURL === 'string') {
        url = controller.historyURL;
      } else {
        throw new Error("ApplicationController#adjustURL: controller for " + this.currentControllerName + " does not provide a historyURL");
      }
      if (params.changeURL) mediator.router.changeURL(url);
      return this.url = url;
    };

    ApplicationController.prototype.dispose = function() {
      var prop, properties, _i, _len, _ref;
      if (this.disposed) return;
      this.disposeCommonControllers();
      if ((_ref = this.currentController) != null) _ref.dispose();
      properties = ['previousControllerName', 'currentControllerName', 'currentController', 'currentAction', 'currentParams', 'url'];
      for (_i = 0, _len = properties.length; _i < _len; _i++) {
        prop = properties[_i];
        delete this[prop];
      }
      return ApplicationController.__super__.dispose.apply(this, arguments);
    };

    return ApplicationController;

  })(Controller);
});
