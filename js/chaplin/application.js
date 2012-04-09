
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
      this.router = new Router();
      if (typeof routes === "function") routes(this.router.match);
      return this.router.startHistory();
    };

    return Application;

  })();
});
