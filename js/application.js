
define(['mediator', 'lib/support', 'controllers/session_controller', 'controllers/application_controller', 'lib/router'], function(mediator, support, SessionController, ApplicationController, Router) {
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
      if (support.propertyDescriptors) {
        return Object.defineProperty(mediator, 'router', {
          writable: false,
          configurable: false,
          enumerable: true
        });
      }
    }
  };
  if (typeof Object.freeze === "function") Object.freeze(Application);
  return Application;
});
