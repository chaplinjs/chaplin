
define(['mediator', 'chaplin/controllers/application_controller', 'chaplin/views/application_view', 'chaplin/lib/router'], function(mediator, ApplicationController, ApplicationView, Router) {
  'use strict';
  var Application;
  return Application = (function() {

    function Application() {}

    Application.prototype.title = '';

    Application.prototype.applicationController = null;

    Application.prototype.applicationView = null;

    Application.prototype.router = null;

    Application.prototype.initialize = function() {
      /*console.debug 'Application#initialize'
      */      this.applicationController = new ApplicationController();
      return this.applicationView = new ApplicationView({
        title: this.title
      });
    };

    Application.prototype.initRouter = function(routes, options) {
      this.router = new Router(options);
      if (typeof routes === "function") routes(this.router.match);
      return this.router.startHistory();
    };

    Application.prototype.disposed = false;

    Application.prototype.dispose = function() {
      /*console.debug 'Application#dispose'
      */
      var prop, properties, _i, _len;
      if (this.disposed) return;
      properties = ['applicationController', 'applicationView', 'router'];
      for (_i = 0, _len = properties.length; _i < _len; _i++) {
        prop = properties[_i];
        this[prop].dispose();
        delete this[prop];
      }
      this.disposed = true;
      return typeof Object.freeze === "function" ? Object.freeze(this) : void 0;
    };

    return Application;

  })();
});
