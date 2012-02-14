var __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['views/collection_view', 'views/post_view', 'text!templates/posts.hbs'], function(CollectionView, PostView, template) {
  'use strict';
  var PostsView;
  return PostsView = (function(_super) {

    __extends(PostsView, _super);

    function PostsView() {
      PostsView.__super__.constructor.apply(this, arguments);
    }

    PostsView.template = template;

    PostsView.prototype.tagName = 'div';

    PostsView.prototype.id = 'posts';

    PostsView.prototype.containerSelector = '#content-container';

    PostsView.prototype.listSelector = 'ol';

    PostsView.prototype.fallbackSelector = '.fallback';

    PostsView.prototype.getView = function(item) {
      return new PostView({
        model: item
      });
    };

    return PostsView;

  })(CollectionView);
});
