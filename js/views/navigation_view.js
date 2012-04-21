var __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['views/view', 'text!templates/navigation.hbs'], function(View, template) {
  'use strict';
  var NavigationView;
  return NavigationView = (function(_super) {

    __extends(NavigationView, _super);

    function NavigationView() {
      NavigationView.__super__.constructor.apply(this, arguments);
    }

    NavigationView.prototype.template = template;

    template = null;

    NavigationView.prototype.id = 'navigation';

    NavigationView.prototype.containerSelector = '#navigation-container';

    NavigationView.prototype.autoRender = true;

    NavigationView.prototype.initialize = function() {
      NavigationView.__super__.initialize.apply(this, arguments);
      return this.subscribeEvent('startupController', this.render);
    };

    return NavigationView;

  })(View);
});
