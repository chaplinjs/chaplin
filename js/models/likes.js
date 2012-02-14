var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['mediator', 'models/collection', 'models/like'], function(mediator, Collection, Like) {
  'use strict';
  var Likes;
  return Likes = (function(_super) {

    __extends(Likes, _super);

    function Likes() {
      this.processLikes = __bind(this.processLikes, this);
      Likes.__super__.constructor.apply(this, arguments);
    }

    Likes.prototype.model = Like;

    Likes.prototype.initialize = function() {
      Likes.__super__.initialize.apply(this, arguments);
      _(this).extend($.Deferred());
      this.getLikes();
      this.subscribeEvent('login', this.getLikes);
      return this.subscribeEvent('logout', this.reset);
    };

    Likes.prototype.getLikes = function() {
      var provider, user;
      user = mediator.user;
      if (!user) return;
      provider = user.get('provider');
      if (provider.name !== 'facebook') return;
      this.trigger('loadStart');
      return provider.getInfo('/me/likes', this.processLikes);
    };

    Likes.prototype.processLikes = function(response) {
      this.trigger('load');
      this.reset(response && response.data ? response.data : []);
      return this.resolve();
    };

    return Likes;

  })(Collection);
});
