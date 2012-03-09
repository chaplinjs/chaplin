var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['mediator', 'models/collection', 'models/like'], function(mediator, Collection, Like) {
  'use strict';
  var Likes;
  return Likes = (function(_super) {

    __extends(Likes, _super);

    function Likes() {
      this.logout = __bind(this.logout, this);
      this.processLikes = __bind(this.processLikes, this);
      this.fetch = __bind(this.fetch, this);
      Likes.__super__.constructor.apply(this, arguments);
    }

    Likes.prototype.model = Like;

    Likes.prototype.initialize = function() {
      Likes.__super__.initialize.apply(this, arguments);
      this.initDeferred();
      this.subscribeEvent('login', this.fetch);
      this.subscribeEvent('logout', this.logout);
      return this.fetch();
    };

    Likes.prototype.fetch = function() {
      var facebook, user;
      user = mediator.user;
      if (!user) return;
      facebook = user.get('provider');
      if (facebook.name !== 'facebook') return;
      this.trigger('loadStart');
      return facebook.getInfo('/me/likes', this.processLikes);
    };

    Likes.prototype.processLikes = function(response) {
      this.trigger('load');
      this.reset(response && response.data ? response.data : []);
      return this.resolve();
    };

    Likes.prototype.logout = function() {
      this.initDeferred();
      return this.reset();
    };

    return Likes;

  })(Collection);
});
