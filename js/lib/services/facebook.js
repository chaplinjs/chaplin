var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['underscore', 'mediator', 'lib/utils', 'lib/services/service_provider'], function(_, mediator, utils, ServiceProvider) {
  'use strict';
  var Facebook;
  return Facebook = (function(_super) {
    var facebookAppId, scope;

    __extends(Facebook, _super);

    facebookAppId = '115149731946795';

    scope = 'user_likes';

    Facebook.prototype.name = 'facebook';

    Facebook.prototype.status = null;

    Facebook.prototype.accessToken = null;

    function Facebook() {
      this.processUserData = __bind(this.processUserData, this);
      this.facebookLogout = __bind(this.facebookLogout, this);
      this.loginStatusAfterAbort = __bind(this.loginStatusAfterAbort, this);
      this.loginHandler = __bind(this.loginHandler, this);
      this.triggerLogin = __bind(this.triggerLogin, this);
      this.loginStatusHandler = __bind(this.loginStatusHandler, this);
      this.getLoginStatus = __bind(this.getLoginStatus, this);
      this.saveAuthResponse = __bind(this.saveAuthResponse, this);
      this.loadHandler = __bind(this.loadHandler, this);      Facebook.__super__.constructor.apply(this, arguments);
      utils.deferMethods({
        deferred: this,
        methods: ['parse', 'subscribe', 'postToGraph', 'getAccumulatedInfo', 'getInfo'],
        onDeferral: this.load
      });
      utils.wrapAccumulators(this, ['getAccumulatedInfo']);
      this.subscribeEvent('logout', this.logout);
    }

    Facebook.prototype.load = function() {
      if (this.state() === 'resolved' || this.loading) return;
      this.loading = true;
      window.fbAsyncInit = this.loadHandler;
      return utils.loadLib('http://connect.facebook.net/en_US/all.js', null, this.reject);
    };

    Facebook.prototype.loadHandler = function() {
      this.loading = false;
      try {
        delete window.fbAsyncInit;
      } catch (error) {
        window.fbAsyncInit = void 0;
      }
      FB.init({
        appId: facebookAppId,
        status: true,
        cookie: true,
        xfbml: false
      });
      this.registerHandlers();
      return this.resolve();
    };

    Facebook.prototype.registerHandlers = function() {
      this.subscribe('auth.logout', this.facebookLogout);
      this.subscribe('edge.create', this.processLike);
      return this.subscribe('comment.create', this.processComment);
    };

    Facebook.prototype.unregisterHandlers = function() {
      this.unsubscribe('auth.logout', this.facebookLogout);
      this.unsubscribe('edge.create', this.processLike);
      return this.unsubscribe('comment.create', this.processComment);
    };

    Facebook.prototype.isLoaded = function() {
      return Boolean(window.FB && FB.login);
    };

    Facebook.prototype.saveAuthResponse = function(response) {
      var authResponse;
      this.status = response.status;
      authResponse = response.authResponse;
      if (authResponse) {
        return this.accessToken = authResponse.accessToken;
      } else {
        return this.accessToken = null;
      }
    };

    Facebook.prototype.getLoginStatus = function(callback, force) {
      if (callback == null) callback = this.loginStatusHandler;
      if (force == null) force = false;
      return FB.getLoginStatus(callback, force);
    };

    Facebook.prototype.loginStatusHandler = function(response) {
      var authResponse;
      this.saveAuthResponse(response);
      authResponse = response.authResponse;
      if (authResponse) {
        this.publishSession(authResponse);
        return this.getUserData();
      } else {
        return mediator.publish('logout');
      }
    };

    Facebook.prototype.triggerLogin = function(loginContext) {
      return FB.login(_(this.loginHandler).bind(this, loginContext), {
        scope: scope
      });
    };

    Facebook.prototype.loginHandler = function(loginContext, response) {
      var authResponse, eventPayload, loginStatusHandler;
      this.saveAuthResponse(response);
      authResponse = response.authResponse;
      eventPayload = {
        provider: this,
        loginContext: loginContext
      };
      if (authResponse) {
        mediator.publish('loginSuccessful', eventPayload);
        this.publishSession(authResponse);
        return this.getUserData();
      } else {
        mediator.publish('loginAbort', eventPayload);
        loginStatusHandler = _(this.loginStatusAfterAbort).bind(this, loginContext);
        return this.getLoginStatus(loginStatusHandler, true);
      }
    };

    Facebook.prototype.loginStatusAfterAbort = function(loginContext, response) {
      var authResponse, eventPayload;
      this.saveAuthResponse(response);
      authResponse = response.authResponse;
      eventPayload = {
        provider: this,
        loginContext: loginContext
      };
      if (authResponse) {
        mediator.publish('loginSuccessful', eventPayload);
        return this.publishSession(authResponse);
      } else {
        return mediator.publish('loginFail', eventPayload);
      }
    };

    Facebook.prototype.publishSession = function(authResponse) {
      return mediator.publish('serviceProviderSession', {
        provider: this,
        userId: authResponse.userID,
        accessToken: authResponse.accessToken
      });
    };

    Facebook.prototype.facebookLogout = function(response) {
      return this.saveAuthResponse(response);
    };

    Facebook.prototype.logout = function() {
      return this.status = this.accessToken = null;
    };

    Facebook.prototype.processLike = function(url) {
      return mediator.publish('facebook:like', url);
    };

    Facebook.prototype.processComment = function(comment) {
      return mediator.publish('facebook:comment', comment.href);
    };

    Facebook.prototype.parse = function(el) {
      return FB.XFBML.parse(el);
    };

    Facebook.prototype.subscribe = function(eventType, handler) {
      return FB.Event.subscribe(eventType, handler);
    };

    Facebook.prototype.unsubscribe = function(eventType, handler) {
      return FB.Event.unsubscribe(eventType, handler);
    };

    Facebook.prototype.postToGraph = function(ogResource, data, callback) {
      return FB.api(ogResource, 'post', data, function(response) {
        if (callback) return callback(response);
      });
    };

    Facebook.prototype.getAccumulatedInfo = function(urls, callback) {
      if (typeof urls === 'string') urls = [urls];
      urls = _(urls).reduce(function(memo, url) {
        if (memo) memo += ',';
        return memo += encodeURIComponent(url);
      }, '');
      return FB.api("?ids=" + urls, callback);
    };

    Facebook.prototype.getInfo = function(id, callback) {
      return FB.api(id, callback);
    };

    Facebook.prototype.getUserData = function() {
      return this.getInfo('/me', this.processUserData);
    };

    Facebook.prototype.processUserData = function(response) {
      return mediator.publish('userData', response);
    };

    Facebook.prototype.dispose = function() {
      if (this.disposed) return;
      this.unregisterHandlers();
      delete this.status;
      delete this.accessToken;
      return Facebook.__super__.dispose.apply(this, arguments);
    };

    return Facebook;

  })(ServiceProvider);
});
