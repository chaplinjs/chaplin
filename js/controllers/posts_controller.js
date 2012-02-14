var __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['controllers/controller', 'models/posts', 'views/posts_view'], function(Controller, Posts, PostsView) {
  'use strict';
  var PostsController;
  return PostsController = (function(_super) {

    __extends(PostsController, _super);

    function PostsController() {
      PostsController.__super__.constructor.apply(this, arguments);
    }

    PostsController.prototype.historyURL = 'posts';

    PostsController.prototype.index = function(params) {
      this.collection = new Posts();
      return this.view = new PostsView({
        collection: this.collection
      });
    };

    return PostsController;

  })(Controller);
});
