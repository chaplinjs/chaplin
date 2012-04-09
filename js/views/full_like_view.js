var __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['mediator', 'chaplin/views/view', 'text!templates/full_like.hbs'], function(mediator, View, template) {
  'use strict';
  var FullLikeView;
  return FullLikeView = (function(_super) {

    __extends(FullLikeView, _super);

    function FullLikeView() {
      FullLikeView.__super__.constructor.apply(this, arguments);
    }

    FullLikeView.prototype.template = template;

    FullLikeView.prototype.id = 'like';

    FullLikeView.prototype.containerSelector = '#content-container';

    FullLikeView.prototype.autoRender = true;

    FullLikeView.prototype.initialize = function() {
      FullLikeView.__super__.initialize.apply(this, arguments);
      if (this.model.state() !== 'resolved') return this.model.done(this.render);
    };

    FullLikeView.prototype.render = function() {
      var provider, user;
      FullLikeView.__super__.render.apply(this, arguments);
      if (this.model.state() === 'resolved') {
        user = mediator.user;
        provider = user.get('provider');
        if (provider.name === 'facebook') return provider.parse(this.el);
      }
    };

    return FullLikeView;

  })(View);
});
