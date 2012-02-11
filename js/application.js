
define(['mediator', 'controllers/session_controller', 'controllers/application_controller', 'lib/router'], function(mediator, SessionController, ApplicationController, Router) {
  'use strict';
  var Application;
  Application = {
    initialize: function() {
      this.startupControllers();
      return this.startupRouter();
    },
    startupControllers: function() {
      var applicationController, sessionController;
      sessionController = new SessionController();
      sessionController.startup();
      applicationController = new ApplicationController();
      return applicationController.startup();
    },
    startupRouter: function() {
      mediator.router = new Router();
      return typeof Object.defineProperty === "function" ? Object.defineProperty(mediator, 'router', {
        writable: false
      }) : void 0;
    }
  };
  Application.initialize();
  return Application;
});
