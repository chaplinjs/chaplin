var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['underscore', 'mediator', 'lib/utils', 'lib/services/service_provider'], function(_, mediator, utils, ServiceProvider) {
  'use strict';
  var Google;
  return Google = (function(_super) {
    var clientId, scopes;

    __extends(Google, _super);

    function Google() {
      this.loadHandler = __bind(this.loadHandler, this);
      Google.__super__.constructor.apply(this, arguments);
    }

    clientId = '365800635017.apps.googleusercontent.com';

    scopes = 'https://www.googleapis.com/auth/userinfo.profile';

    Google.prototype.name = 'google';

    Google.prototype.load = function() {
      /*console.debug 'Google#load'
      */      if (this.state() === 'resolved' || this.loading) return;
      this.loading = true;
      window.googleClientLoaded = this.loadHandler;
      return utils.loadLib('https://apis.google.com/js/client.js?onload=googleClientLoaded', null, this.reject);
    };

    Google.prototype.loadHandler = function() {
      /*console.debug 'Google#loadHandler', @isLoaded()
      */      try {
        delete window.googleClientLoaded;
      } catch (error) {
        window.googleClientLoaded = void 0;
      }
      return gapi.auth.init(this.resolve);
    };

    Google.prototype.isLoaded = function() {
      return Boolean(window.gapi && gapi.auth && gapi.auth.authorize);
    };

    Google.prototype.triggerLogin = function(loginContext) {
      /*console.debug 'Google#triggerLogin', loginContext
      */      return gapi.auth.authorize({
        client_id: clientId,
        scope: scopes,
        immediate: false
      }, _(this.loginHandler).bind(this, loginContext));
    };

    Google.prototype.loginHandler = function(loginContext, authResponse) {
      /*console.debug 'Google#loginHandler', loginContext, authResponse
      */      if (authResponse) {
        mediator.publish('loginSuccessful', {
          provider: this,
          loginContext: loginContext
        });
        return mediator.publish('serviceProviderSession', {
          provider: this,
          accessToken: authResponse.access_token
        });
      } else {
        return mediator.publish('loginFail', {
          provider: this,
          loginContext: loginContext
        });
      }
    };

    Google.prototype.getLoginStatus = function(callback) {
      /*console.debug 'Google#getLoginStatus immediate: true'
      */      return gapi.auth.authorize({
        client_id: clientId,
        scope: scopes,
        immediate: true
      }, callback);
    };

    Google.prototype.getUserInfo = function(callback) {
      var request;
      request = gapi.client.request({
        path: '/oauth2/v2/userinfo'
      });
      return request.execute(callback);
    };

    Google.prototype.parsePlusOneButton = function(el) {
      if (window.gapi && gapi.plusone && gapi.plusone.go) {
        return gapi.plusone.go(el);
      } else {
        window.___gcfg = {
          parsetags: 'explicit'
        };
        return utils.loadLib('https://apis.google.com/js/plusone.js', function() {
          try {
            delete window.___gcfg;
          } catch (error) {
            window.___gcfg = void 0;
          }
          return gapi.plusone.go(el);
        });
      }
    };

    return Google;

  })(ServiceProvider);
});
