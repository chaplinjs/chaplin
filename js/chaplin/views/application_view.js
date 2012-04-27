var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

define(['jquery', 'underscore', 'mediator', 'chaplin/lib/utils', 'chaplin/lib/subscriber'], function($, _, mediator, utils, Subscriber) {
  'use strict';
  var ApplicationView;
  return ApplicationView = (function() {

    _(ApplicationView.prototype).extend(Subscriber);

    ApplicationView.prototype.title = '';

    function ApplicationView(options) {
      if (options == null) options = {};
      this.openLink = __bind(this.openLink, this);
      /*console.debug 'ApplicationView#constructor', options
      */
      this.title = options.title;
      this.subscribeEvent('beforeControllerDispose', this.hideOldView);
      this.subscribeEvent('startupController', this.showNewView);
      this.subscribeEvent('startupController', this.removeFallbackContent);
      this.subscribeEvent('startupController', this.adjustTitle);
      this.subscribeEvent('loginStatus', this.updateBodyClasses);
      this.updateBodyClasses();
      this.addDOMHandlers();
    }

    ApplicationView.prototype.hideOldView = function(controller) {
      var view;
      scrollTo(0, 0);
      view = controller.view;
      if (view) return view.$el.css('display', 'none');
    };

    ApplicationView.prototype.showNewView = function(context) {
      var view;
      view = context.controller.view;
      if (view) {
        return view.$el.css({
          display: 'block',
          opacity: 1,
          visibility: 'visible'
        });
      }
    };

    ApplicationView.prototype.adjustTitle = function(context) {
      var subtitle, title;
      title = this.title;
      subtitle = context.controller.title;
      if (subtitle) title = "" + subtitle + " \u2013 " + title;
      return setTimeout((function() {
        return document.title = title;
      }), 50);
    };

    ApplicationView.prototype.updateBodyClasses = function(loggedIn) {
      return $(document.body).toggleClass('logged-out', !loggedIn).toggleClass('logged-in', loggedIn);
    };

    ApplicationView.prototype.removeFallbackContent = function() {
      $('.accessible-fallback').remove();
      return this.unsubscribeEvent('startupController', this.removeFallbackContent);
    };

    ApplicationView.prototype.addDOMHandlers = function() {
      return $(document).delegate('.go-to', 'click', this.goToHandler).delegate('a', 'click', this.openLink);
    };

    ApplicationView.prototype.openLink = function(event) {
      var currentHostname, el, external, hostnameRegExp, href;
      if (utils.modifierKeyPressed(event)) return;
      el = event.currentTarget;
      href = el.getAttribute('href');
      if (href === '' || href.charAt(0) === '#') return;
      currentHostname = location.hostname.replace('.', '\\.');
      hostnameRegExp = RegExp("" + currentHostname + "$", "i");
      external = !hostnameRegExp.test(el.hostname);
      if (external) return;
      return this.openInternalLink(event);
    };

    ApplicationView.prototype.openInternalLink = function(event) {
      var el, path;
      if (utils.modifierKeyPressed(event)) return;
      el = event.currentTarget;
      path = el.pathname;
      if (!path) return;
      return mediator.publish('!router:route', path, function(routed) {
        if (routed) return event.preventDefault();
      });
    };

    ApplicationView.prototype.goToHandler = function(event) {
      var el, path;
      el = event.currentTarget;
      if (event.nodeName === 'A') return;
      path = $(el).data('href');
      if (!path) return;
      return mediator.publish('!router:route', path, function(routed) {
        if (routed) {
          return event.preventDefault();
        } else {
          return location.href = path;
        }
      });
    };

    ApplicationView.prototype.disposed = false;

    ApplicationView.prototype.dispose = function() {
      /*console.debug 'ApplicationView#dispose'
      */      if (this.disposed) return;
      this.unsubscribeAllEvents();
      delete this.title;
      this.disposed = true;
      return typeof Object.freeze === "function" ? Object.freeze(this) : void 0;
    };

    return ApplicationView;

  })();
});
