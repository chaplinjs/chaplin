var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

define(['mediator', 'lib/utils'], function(mediator, utils) {
  'use strict';
  var ApplicationView;
  return ApplicationView = (function() {
    var siteTitle;

    siteTitle = 'Architecture Example';

    ApplicationView.prototype.previousController = null;

    ApplicationView.prototype.currentControllerName = null;

    ApplicationView.prototype.currentController = null;

    ApplicationView.prototype.currentAction = null;

    ApplicationView.prototype.currentView = null;

    ApplicationView.prototype.currentParams = null;

    ApplicationView.prototype.url = null;

    function ApplicationView() {
      this.openLink = __bind(this.openLink, this);
      this.removeFallbackContent = __bind(this.removeFallbackContent, this);
      this.startupController = __bind(this.startupController, this);
      this.matchRoute = __bind(this.matchRoute, this);
      this.logout = __bind(this.logout, this);
      this.login = __bind(this.login, this);      if (!mediator.user) this.logout();
      mediator.subscribe('matchRoute', this.matchRoute);
      mediator.subscribe('!startupController', this.startupController);
      mediator.subscribe('login', this.login);
      mediator.subscribe('logout', this.logout);
      mediator.subscribe('startupController', this.removeFallbackContent);
      this.addGlobalHandlers();
    }

    ApplicationView.prototype.login = function(user) {
      return $(document.body).removeClass('logged-out').addClass('logged-in');
    };

    ApplicationView.prototype.logout = function() {
      return $(document.body).removeClass('logged-in').addClass('logged-out');
    };

    ApplicationView.prototype.matchRoute = function(route, params) {
      var action, controllerName;
      controllerName = route.controller;
      action = route.action;
      return this.startupController(controllerName, action, params);
    };

    ApplicationView.prototype.startupController = function(controllerName, action, params) {
      var controllerFileName, sameController;
      if (action == null) action = 'index';
      if (params == null) params = {};
      if (params.changeURL !== false) params.changeURL = true;
      if (params.forceStartup !== true) params.forceStartup = false;
      sameController = !params.forceStartup && this.currentControllerName === controllerName && this.currentAction === action && (!this.currentParams || _(params).isEqual(this.currentParams));
      if (sameController) return;
      controllerFileName = utils.underscorize(controllerName) + '_controller';
      return require(['controllers/' + controllerFileName], _(this.controllerLoaded).bind(this, controllerName, action, params));
    };

    ApplicationView.prototype.controllerLoaded = function(controllerName, action, params, ControllerConstructor) {
      var controller, currentController, currentControllerName, currentView, view;
      currentControllerName = this.currentControllerName || null;
      currentController = this.currentController || null;
      if (this.currentController) currentView = this.currentController.view;
      scrollTo(0, 0);
      if (currentView && currentView.$container) {
        currentView.$container.css('display', 'none');
      }
      if (currentController) {
        if (typeof currentController.dispose !== 'function') {
          throw new Error("ApplicationView#controllerLoaded: dispose method not found on " + currentControllerName + " controller");
        }
        currentController.dispose(params, controllerName);
      }
      controller = new ControllerConstructor();
      if (typeof controller.startup !== 'function') {
        throw new Error("ApplicationView#controllerLoaded: startup method not found on " + controllerName + " controller");
      }
      controller.startup(params, currentControllerName);
      if (typeof controller[action] !== 'function') {
        throw new Error("ApplicationView#controllerLoaded: action " + action + " not found on " + controllerName + " controller");
      }
      controller[action](params, currentControllerName);
      view = controller.view;
      if (view && view.$container) {
        view.$container.css({
          display: 'block',
          opacity: 1
        });
      }
      this.previousController = currentControllerName;
      this.currentControllerName = controllerName;
      this.currentController = controller;
      this.currentAction = action;
      this.currentView = view;
      this.currentParams = params;
      this.adjustURL();
      this.adjustTitle();
      return mediator.publish('startupController', this.currentControllerName, this.currentParams, this.previousController);
    };

    ApplicationView.prototype.adjustURL = function() {
      var controller, historyURL, params;
      controller = this.currentController;
      params = this.currentParams;
      if (typeof controller.historyURL === 'function') {
        historyURL = controller.historyURL(params);
      } else if (typeof controller.historyURL === 'string') {
        historyURL = controller.historyURL;
      } else {
        throw new Error("ApplicationView#adjustURL: controller for " + controllerName + " does not provide a historyURL");
      }
      if (params.changeURL) mediator.router.changeURL(historyURL);
      return this.url = historyURL;
    };

    ApplicationView.prototype.adjustTitle = function() {
      var subtitle, title;
      title = siteTitle;
      subtitle = this.currentParams.title || this.currentController.title;
      if (subtitle) title += " \u2013 " + subtitle;
      return setTimeout((function() {
        return document.title = title;
      }), 50);
    };

    ApplicationView.prototype.removeFallbackContent = function() {
      $('#startup-loading, .accessible-fallback').remove();
      return mediator.unsubscribe('startupController', this.removeFallbackContent);
    };

    ApplicationView.prototype.addGlobalHandlers = function() {
      return $(document).delegate('#logout-button', 'click', this.logoutButtonClick).delegate('.go-to', 'click', this.goToHandler).delegate('a', 'click', this.openLink);
    };

    ApplicationView.prototype.openLink = function(e) {
      var currentHostname, el, external, hostname, hostnameRegExp, href, hrefAttr;
      el = e.currentTarget;
      hrefAttr = el.getAttribute('href');
      if (hrefAttr === '' || /^#/.test(hrefAttr)) return;
      href = el.href;
      hostname = el.hostname;
      if (!(href && hostname)) return;
      currentHostname = location.hostname.replace('.', '\\.');
      hostnameRegExp = new RegExp("" + currentHostname + "$", 'i');
      external = !hostnameRegExp.test(hostname);
      if (external) return;
      return this.openInternalLink(e);
    };

    ApplicationView.prototype.openInternalLink = function(e) {
      var el, path, result;
      e.preventDefault();
      el = e.currentTarget;
      path = el.pathname;
      if (!path) return;
      result = mediator.router.route(path);
      if (result) return e.preventDefault();
    };

    ApplicationView.prototype.goToHandler = function(e) {
      var el, path, result;
      el = e.currentTarget;
      if (e.nodeName === 'A') return;
      path = $(el).data('href');
      if (!path) return;
      result = mediator.router.route(path);
      if (result) return e.preventDefault();
    };

    ApplicationView.prototype.logoutButtonClick = function(e) {
      e.preventDefault();
      return mediator.publish('!logout');
    };

    return ApplicationView;

  })();
});
