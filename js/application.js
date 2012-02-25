
define(['mediator', 'controllers/session_controller', 'controllers/application_controller', 'lib/router'], function(mediator, SessionController, ApplicationController, Router) {
  'use strict';
  var Application;
  Application = {
    initialize: function() {
      this.initControllers();
      return this.initRouter();
    },
    initControllers: function() {
      new SessionController();
      return new ApplicationController();
    },
    initRouter: function() {
      mediator.router = new Router();
      return typeof Object.defineProperty === "function" ? Object.defineProperty(mediator, 'router', {
        writable: false
      }) : void 0;
    }
  };
  Application.initialize();
  return Application;
});
