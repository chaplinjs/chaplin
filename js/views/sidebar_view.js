var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['mediator', 'views/view', 'text!templates/sidebar.hbs'], function(mediator, View, template) {
  'use strict';
  var SidebarView;
  return SidebarView = (function(_super) {

    __extends(SidebarView, _super);

    function SidebarView() {
      this.loginStatusHandler = __bind(this.loginStatusHandler, this);
      SidebarView.__super__.constructor.apply(this, arguments);
    }

    SidebarView.prototype.template = template;

    template = null;

    SidebarView.prototype.id = 'sidebar';

    SidebarView.prototype.containerSelector = '#sidebar-container';

    SidebarView.prototype.autoRender = true;

    SidebarView.prototype.initialize = function() {
      SidebarView.__super__.initialize.apply(this, arguments);
      this.subscribeEvent('loginStatus', this.loginStatusHandler);
      this.subscribeEvent('userData', this.render);
      return this.delegate('click', '#logout-button', this.logoutButtonClick);
    };

    SidebarView.prototype.loginStatusHandler = function(loggedIn) {
      /*console.debug 'SidebarView#loginStatusHandler', loggedIn
      */      if (loggedIn) {
        this.model = mediator.user;
      } else {
        this.model = null;
      }
      return this.render();
    };

    SidebarView.prototype.logoutButtonClick = function(event) {
      event.preventDefault();
      return mediator.publish('!logout');
    };

    return SidebarView;

  })(View);
});
