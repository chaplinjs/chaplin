var __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['views/collection_view', 'views/compact_like_view', 'text!templates/likes.hbs'], function(CollectionView, CompactLikeView, template) {
  'use strict';
  var LikesView;
  return LikesView = (function(_super) {

    __extends(LikesView, _super);

    function LikesView() {
      LikesView.__super__.constructor.apply(this, arguments);
    }

    LikesView.template = template;

    LikesView.prototype.tagName = 'div';

    LikesView.prototype.id = 'likes';

    LikesView.prototype.containerSelector = '#content-container';

    LikesView.prototype.initialize = function() {
      LikesView.__super__.initialize.apply(this, arguments);
      this.subscribeEvent('loginStatus', this.loginStatus);
      return this.bind('visibilityChange', this.visibilityChangeHandler);
    };

    LikesView.prototype.getView = function(item) {
      return new CompactLikeView({
        model: item
      });
    };

    LikesView.prototype.loginStatus = function(loginStatus) {
      return this.$('.login-note').css('display', loginStatus ? 'none' : 'block');
    };

    LikesView.prototype.visibilityChangeHandler = function(visibleItems) {
      var empty;
      empty = visibleItems.length === 0 && this.collection.state() === 'resolved';
      return this.$fallback.css('display', empty ? 'block' : 'none');
    };

    LikesView.prototype.render = function() {
      LikesView.__super__.render.apply(this, arguments);
      this.$container.append(this.el);
      this.$listElement = $('#likes-list');
      return this.$fallback = this.$('.fallback');
    };

    return LikesView;

  })(CollectionView);
});
