var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['mediator', 'models/collection', 'models/post'], function(mediator, Collection, Post) {
  'use strict';
  var Posts;
  return Posts = (function(_super) {

    __extends(Posts, _super);

    function Posts() {
      this.logout = __bind(this.logout, this);
      this.processPosts = __bind(this.processPosts, this);
      this.fetch = __bind(this.fetch, this);
      Posts.__super__.constructor.apply(this, arguments);
    }

    Posts.prototype.model = Post;

    Posts.prototype.initialize = function() {
      Posts.__super__.initialize.apply(this, arguments);
      this.initDeferred();
      this.subscribeEvent('login', this.fetch);
      this.subscribeEvent('logout', this.logout);
      return this.fetch();
    };

    Posts.prototype.fetch = function() {
      var facebook, user;
      user = mediator.user;
      if (!user) return;
      facebook = user.get('provider');
      if (facebook.name !== 'facebook') return;
      this.trigger('loadStart');
      return facebook.getInfo('/158352134203230/feed', this.processPosts);
    };

    Posts.prototype.processPosts = function(response) {
      var posts;
      this.trigger('load');
      posts = response && response.data ? response.data : [];
      posts = _(posts).filter(function(post) {
        return post.from && post.from.name === 'moviepilot.com';
      });
      this.reset(posts);
      return this.resolve();
    };

    Posts.prototype.logout = function() {
      this.initDeferred();
      return this.reset();
    };

    return Posts;

  })(Collection);
});
