
define(['mediator', 'chaplin/controllers/application_controller', 'chaplin/views/application_view', 'chaplin/lib/router', 'lib/view_helper'], function(mediator, ApplicationController, ApplicationView, Router) {
  'use strict';
  var Application;
  return Application = (function() {

    function Application() {}

    Application.prototype.title = '';

    Application.prototype.initialize = function() {
      this.applicationController = new ApplicationController();
      return this.applicationView = new ApplicationView({
        title: this.title
      });
    };

    Application.prototype.initRouter = function(routes) {
      var router;
      router = new Router();
      mediator.setRouter(router);
      if (typeof routes === "function") routes(router.match);
      return router.startHistory();
    };

    return Application;

  })();
});
