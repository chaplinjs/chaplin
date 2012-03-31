
define(['mediator', 'controllers/session_controller', 'controllers/application_controller', 'lib/router', 'routes'], function(mediator, SessionController, ApplicationController, Router, registerRoutes) {
  'use strict';
  var Application;
  Application = {
    initialize: function() {
      this.initControllers();
      this.initRouter();
      if (typeof Object.freeze === "function") Object.freeze(this);
    },
    initControllers: function() {
      this.sessionController = new SessionController();
      return this.applicationController = new ApplicationController();
    },
    initRouter: function() {
      this.router = new Router();
      mediator.setRouter(this.router);
      registerRoutes(this.router.match);
      return this.router.startHistory();
    }
  };
  return Application;
});
