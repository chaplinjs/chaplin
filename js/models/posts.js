var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['mediator', 'models/collection', 'models/post'], function(mediator, Collection, Post) {
  'use strict';
  var Posts;
  return Posts = (function(_super) {

    __extends(Posts, _super);

    function Posts() {
      this.processPosts = __bind(this.processPosts, this);
      Posts.__super__.constructor.apply(this, arguments);
    }

    Posts.prototype.model = Post;

    Posts.prototype.initialize = function() {
      Posts.__super__.initialize.apply(this, arguments);
      _(this).extend($.Deferred());
      this.getPosts();
      this.subscribeEvent('login', this.getPosts);
      return this.subscribeEvent('logout', this.reset);
    };

    Posts.prototype.getPosts = function() {
      var provider, user;
      user = mediator.user;
      if (!user) return;
      provider = user.get('provider');
      if (provider.name !== 'facebook') return;
      this.trigger('loadStart');
      return provider.getInfo('/158352134203230/feed', this.processPosts);
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

    return Posts;

  })(Collection);
});
