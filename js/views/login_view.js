var __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['underscore', 'mediator', 'lib/utils', 'views/view', 'text!templates/login.hbs'], function(_, mediator, utils, View, template) {
  'use strict';
  var LoginView;
  return LoginView = (function(_super) {

    __extends(LoginView, _super);

    function LoginView() {
      LoginView.__super__.constructor.apply(this, arguments);
    }

    LoginView.prototype.template = template;

    template = null;

    LoginView.prototype.id = 'login';

    LoginView.prototype.containerSelector = '#sidebar-container';

    LoginView.prototype.autoRender = true;

    LoginView.prototype.initialize = function(options) {
      LoginView.__super__.initialize.apply(this, arguments);
      /*console.debug 'LoginView#initialize', @el, options, options.serviceProviders
      */
      return this.initButtons(options.serviceProviders);
    };

    LoginView.prototype.initButtons = function(serviceProviders) {
      /*console.debug 'LoginView#initButtons', serviceProviders
      */
      var buttonSelector, failed, loaded, loginHandler, serviceProvider, serviceProviderName, _results;
      _results = [];
      for (serviceProviderName in serviceProviders) {
        serviceProvider = serviceProviders[serviceProviderName];
        buttonSelector = "." + serviceProviderName;
        this.$(buttonSelector).addClass('service-loading');
        loginHandler = _(this.loginWith).bind(this, serviceProviderName, serviceProvider);
        this.delegate('click', buttonSelector, loginHandler);
        loaded = _(this.serviceProviderLoaded).bind(this, serviceProviderName, serviceProvider);
        serviceProvider.done(loaded);
        failed = _(this.serviceProviderFailed).bind(this, serviceProviderName, serviceProvider);
        _results.push(serviceProvider.fail(failed));
      }
      return _results;
    };

    LoginView.prototype.loginWith = function(serviceProviderName, serviceProvider, e) {
      /*console.debug 'LoginView#loginWith', serviceProviderName, serviceProvider
      */      e.preventDefault();
      if (!serviceProvider.isLoaded()) return;
      mediator.publish('login:pickService', serviceProviderName);
      return mediator.publish('!login', serviceProviderName);
    };

    LoginView.prototype.serviceProviderLoaded = function(serviceProviderName) {
      /*console.debug 'LoginView#serviceProviderLoaded', serviceProviderName
      */      return this.$("." + serviceProviderName).removeClass('service-loading');
    };

    LoginView.prototype.serviceProviderFailed = function(serviceProviderName) {
      /*console.debug 'LoginView#serviceProviderFailed', serviceProviderName
      */      return this.$("." + serviceProviderName).removeClass('service-loading').addClass('service-unavailable').attr('disabled', true).attr('title', 'Error connecting. Please check whether you are blocking ' + ("" + (utils.upcase(serviceProviderName)) + "."));
    };

    return LoginView;

  })(View);
});
