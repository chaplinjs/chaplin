
define(['mediator', 'controllers/session_controller', 'controllers/application_controller', 'lib/router'], function(mediator, SessionController, ApplicationController, Router) {
  'use strict';
  var Application;
  Application = {
    initialize: function() {
      this.initControllers();
      this.initRouter();
    },
    initControllers: function() {
      new SessionController();
      return new ApplicationController();
    },
    initRouter: function() {
      mediator.router = new Router();
      return typeof Object.defineProperty === "function" ? Object.defineProperty(mediator, 'router', {
        writable: false,
        configurable: false,
        enumerable: true
      }) : void 0;
    }
  };
  if (typeof Object.freeze === "function") Object.freeze(Application);
  return Application;
});
