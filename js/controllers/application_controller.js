var __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['controllers/controller', 'views/application_view', 'controllers/navigation_controller', 'controllers/sidebar_controller'], function(Controller, ApplicationView, NavigationController, SidebarController) {
  'use strict';
  var ApplicationController;
  return ApplicationController = (function(_super) {

    __extends(ApplicationController, _super);

    function ApplicationController() {
      ApplicationController.__super__.constructor.apply(this, arguments);
    }

    ApplicationController.prototype.startup = function() {
      this.startupApplication();
      return this.startupSidebars();
    };

    ApplicationController.prototype.startupApplication = function() {
      return new ApplicationView();
    };

    ApplicationController.prototype.startupSidebars = function() {
      var navigationController, sidebarController;
      navigationController = new NavigationController();
      navigationController.startup();
      sidebarController = new SidebarController();
      return sidebarController.startup();
    };

    return ApplicationController;

  })(Controller);
});
