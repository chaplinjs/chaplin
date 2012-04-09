var __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['mediator', 'views/collection_view', 'views/post_view', 'text!templates/posts.hbs'], function(mediator, CollectionView, PostView, template) {
  'use strict';
  var PostsView;
  return PostsView = (function(_super) {

    __extends(PostsView, _super);

    function PostsView() {
      PostsView.__super__.constructor.apply(this, arguments);
    }

    PostsView.prototype.template = template;

    PostsView.prototype.tagName = 'div';

    PostsView.prototype.id = 'posts';

    PostsView.prototype.containerSelector = '#content-container';

    PostsView.prototype.listSelector = 'ol';

    PostsView.prototype.fallbackSelector = '.fallback';

    PostsView.prototype.initialize = function() {
      PostsView.__super__.initialize.apply(this, arguments);
      return this.subscribeEvent('loginStatus', this.showHideLoginNote);
    };

    PostsView.prototype.getView = function(item) {
      return new PostView({
        model: item
      });
    };

    PostsView.prototype.showHideLoginNote = function() {
      return this.$('.login-note').css('display', mediator.user ? 'none' : 'block');
    };

    PostsView.prototype.render = function() {
      PostsView.__super__.render.apply(this, arguments);
      return this.showHideLoginNote();
    };

    return PostsView;

  })(CollectionView);
});
