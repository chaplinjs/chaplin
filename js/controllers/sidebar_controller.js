var __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['controllers/controller', 'views/sidebar_view'], function(Controller, SidebarView) {
  'use strict';
  var SidebarController;
  return SidebarController = (function(_super) {

    __extends(SidebarController, _super);

    function SidebarController() {
      SidebarController.__super__.constructor.apply(this, arguments);
    }

    SidebarController.prototype.initialize = function() {
      return this.view = new SidebarView();
    };

    return SidebarController;

  })(Controller);
});
