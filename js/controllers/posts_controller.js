// Generated by CoffeeScript 1.3.1
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['chaplin/controllers/controller', 'models/posts', 'views/posts_view'], function(Controller, Posts, PostsView) {
  'use strict';

  var PostsController;
  return PostsController = (function(_super) {

    __extends(PostsController, _super);

    PostsController.name = 'PostsController';

    function PostsController() {
      return PostsController.__super__.constructor.apply(this, arguments);
    }

    PostsController.prototype.title = 'Facebook Wall Posts';

    PostsController.prototype.historyURL = 'posts';

    PostsController.prototype.index = function(params) {
      this.posts = new Posts();
      return this.view = new PostsView({
        collection: this.posts
      });
    };

    return PostsController;

  })(Controller);
});
