
define(['underscore', 'mediator', 'chaplin/lib/utils', 'chaplin/lib/subscriber'], function(_, mediator, utils, Subscriber) {
  'use strict';
  var ApplicationController;
  return ApplicationController = (function() {

    _(ApplicationController.prototype).extend(Subscriber);

    ApplicationController.prototype.previousControllerName = null;

    ApplicationController.prototype.currentControllerName = null;

    ApplicationController.prototype.currentController = null;

    ApplicationController.prototype.currentAction = null;

    ApplicationController.prototype.currentParams = null;

    ApplicationController.prototype.url = null;

    function ApplicationController() {
      this.initialize();
    }

    ApplicationController.prototype.initialize = function() {
      /*console.debug 'ApplicationController#initialize'
      */      this.subscribeEvent('matchRoute', this.matchRoute);
      return this.subscribeEvent('!startupController', this.startupController);
    };

    ApplicationController.prototype.matchRoute = function(route, params) {
      /*console.debug 'ApplicationController#matchRoute'
      */      return this.startupController(route.controller, route.action, params);
    };

    ApplicationController.prototype.startupController = function(controllerName, action, params) {
      var controllerFileName, handler, isSameController;
      if (action == null) action = 'index';
      if (params == null) params = {};
      /*console.debug 'ApplicationController#startupController', controllerName, action, params
      */
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
      controller = new ControllerConstructor(params, currentControllerName);
      controller[action](params, currentControllerName);
      this.previousControllerName = currentControllerName;
      this.currentControllerName = controllerName;
      this.currentController = controller;
      this.currentAction = action;
      this.currentParams = params;
      this.adjustURL(controller, params);
      /*console.debug 'publish startupController'
      */
      return mediator.publish('startupController', {
        previousControllerName: this.previousControllerName,
        controller: this.currentController,
        controllerName: this.currentControllerName,
        params: this.currentParams
      });
    };

    ApplicationController.prototype.adjustURL = function(controller, params) {
      var url;
      if (params.path) {
        url = params.path;
      } else if (typeof controller.historyURL === 'function') {
        url = controller.historyURL(params);
      } else if (typeof controller.historyURL === 'string') {
        url = controller.historyURL;
      } else {
        throw new Error('ApplicationController#adjustURL: controller for ' + ("" + this.currentControllerName + " does not provide a historyURL"));
      }
      if (params.changeURL) mediator.publish('!router:changeURL', url);
      return this.url = url;
    };

    ApplicationController.prototype.disposed = false;

    ApplicationController.prototype.dispose = function() {
      if (this.disposed) return;
      this.unsubscribeAllEvents();
      this.disposed = true;
      return typeof Object.freeze === "function" ? Object.freeze(this) : void 0;
    };

    return ApplicationController;

  })();
});
