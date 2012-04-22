var __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['mediator', 'chaplin/application', 'controllers/session_controller', 'controllers/navigation_controller', 'controllers/sidebar_controller', 'routes'], function(mediator, Application, SessionController, NavigationController, SidebarController, routes) {
  'use strict';
  var ExampleApplication;
  return ExampleApplication = (function(_super) {

    __extends(ExampleApplication, _super);

    function ExampleApplication() {
      ExampleApplication.__super__.constructor.apply(this, arguments);
    }

    ExampleApplication.prototype.title = 'Chaplin Example Application';

    ExampleApplication.prototype.initialize = function() {
      ExampleApplication.__super__.initialize.apply(this, arguments);
      new SessionController();
      new NavigationController();
      new SidebarController();
      this.initRouter(routes);
      return typeof Object.freeze === "function" ? Object.freeze(this) : void 0;
    };

    return ExampleApplication;

  })(Application);
});
