var __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['chaplin/controllers/controller', 'models/likes', 'models/like', 'views/likes_view', 'views/full_like_view'], function(Controller, Likes, Like, LikesView, FullLikeView) {
  'use strict';
  var LikesController;
  return LikesController = (function(_super) {

    __extends(LikesController, _super);

    function LikesController() {
      LikesController.__super__.constructor.apply(this, arguments);
    }

    LikesController.prototype.title = 'Your Likes';

    LikesController.prototype.historyURL = function(params) {
      if (params.id) {
        return "likes/" + params.id;
      } else {
        return '';
      }
    };

    LikesController.prototype.index = function(params) {
      /*console.debug 'LikesController#index'
      */      this.likes = new Likes();
      return this.view = new LikesView({
        collection: this.likes
      });
    };

    LikesController.prototype.show = function(params) {
      /*console.debug 'LikesController#show'
      */      this.like = new Like({
        id: params.id
      }, {
        loadDetails: true
      });
      return this.view = new FullLikeView({
        model: this.like
      });
    };

    return LikesController;

  })(Controller);
});
