var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

define(['mediator', 'lib/utils'], function(mediator, utils) {
  'use strict';
  var ApplicationView;
  return ApplicationView = (function() {
    var siteTitle;

    siteTitle = 'Chaplin Example Application';

    function ApplicationView() {
      this.openLink = __bind(this.openLink, this);
      this.removeFallbackContent = __bind(this.removeFallbackContent, this);
      this.updateBodyClasses = __bind(this.updateBodyClasses, this);      mediator.subscribe('login', this.updateBodyClasses);
      mediator.subscribe('logout', this.updateBodyClasses);
      mediator.subscribe('beforeControllerDispose', this.hideOldView);
      mediator.subscribe('startupController', this.showNewView);
      mediator.subscribe('startupController', this.removeFallbackContent);
      mediator.subscribe('startupController', this.adjustTitle);
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
      title = siteTitle;
      subtitle = context.controller.title;
      if (subtitle) title = "" + subtitle + " \u2013 " + title;
      return setTimeout((function() {
        return document.title = title;
      }), 50);
    };

    ApplicationView.prototype.updateBodyClasses = function() {
      var body, loggedIn;
      body = $(document.body);
      loggedIn = Boolean(mediator.user);
      return body.toggleClass('logged-out', !loggedIn).toggleClass('logged-in', loggedIn);
    };

    ApplicationView.prototype.removeFallbackContent = function() {
      $('.accessible-fallback').remove();
      return mediator.unsubscribe('startupController', this.removeFallbackContent);
    };

    ApplicationView.prototype.addDOMHandlers = function() {
      return $(document).delegate('#logout-button', 'click', this.logoutButtonClick).delegate('.go-to', 'click', this.goToHandler).delegate('a', 'click', this.openLink);
    };

    ApplicationView.prototype.openLink = function(event) {
      var currentHostname, el, external, hostname, hostnameRegExp, href, hrefAttr;
      if (utils.modifierKeyPressed(event)) return;
      el = event.currentTarget;
      hrefAttr = el.getAttribute('href');
      if (hrefAttr === '' || /^#/.test(hrefAttr)) return;
      href = el.href;
      hostname = el.hostname;
      if (!(href && hostname)) return;
      currentHostname = location.hostname.replace('.', '\\.');
      hostnameRegExp = RegExp("" + currentHostname + "$", "i");
      external = !hostnameRegExp.test(hostname);
      if (external) return;
      return this.openInternalLink(event);
    };

    ApplicationView.prototype.openInternalLink = function(event) {
      var el, path, result;
      event.preventDefault();
      el = event.currentTarget;
      path = el.pathname;
      if (!path) return;
      result = mediator.router.route(path);
      if (result) return event.preventDefault();
    };

    ApplicationView.prototype.goToHandler = function(event) {
      var el, path, result;
      el = event.currentTarget;
      if (event.nodeName === 'A') return;
      path = $(el).data('href');
      if (!path) return;
      result = mediator.router.route(path);
      if (result) return event.preventDefault();
    };

    ApplicationView.prototype.logoutButtonClick = function(event) {
      event.preventDefault();
      return mediator.publish('!logout');
    };

    return ApplicationView;

  })();
});
