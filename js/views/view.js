var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['lib/utils', 'lib/subscriber', 'lib/view_helper'], function(utils, Subscriber) {
  'use strict';
  var View;
  return View = (function(_super) {

    __extends(View, _super);

    function View() {
      this.dispose = __bind(this.dispose, this);
      this.render = __bind(this.render, this);
      View.__super__.constructor.apply(this, arguments);
    }

    _(View.prototype).defaults(Subscriber);

    View.prototype.containerSelector = null;

    View.prototype.$container = null;

    View.prototype.initialize = function() {
      if (this.model || this.collection) this.modelBind('dispose', this.dispose);
      if (this.containerSelector) {
        return this.$container = $(this.containerSelector);
      }
    };

    View.prototype.delegateEvents = function() {};

    View.prototype.pass = function(eventType, selector) {
      var model,
        _this = this;
      model = this.model || this.collection;
      return this.modelBind(eventType, function(model, val) {
        return _this.$(selector).html(val);
      });
    };

    View.prototype.delegate = function(eventType, second, third) {
      var handler, selector;
      if (typeof eventType !== 'string') {
        throw new TypeError('View#delegate: first argument must be a string');
      }
      if (arguments.length === 2) {
        handler = second;
      } else if (arguments.length === 3) {
        selector = second;
        if (typeof selector !== 'string') {
          throw new TypeError('View#delegate: second argument must be a string');
        }
        handler = third;
      } else {
        console.trace();
        throw new TypeError('View#delegate: only two or three arguments are allowed');
      }
      if (typeof handler !== 'function') {
        throw new TypeError('View#delegate: handler argument must be function');
      }
      eventType += ".delegate" + this.cid;
      handler = _(handler).bind(this);
      if (selector) {
        return this.$el.on(eventType, selector, handler);
      } else {
        return this.$el.on(eventType, handler);
      }
    };

    View.prototype.undelegate = function() {
      return this.$el.unbind(".delegate" + this.cid);
    };

    View.prototype.modelBind = function(type, handler) {
      var handlers, model, _base;
      if (typeof type !== 'string') {
        throw new TypeError('View#modelBind: type argument must be string');
      }
      if (typeof handler !== 'function') {
        throw new TypeError('View#modelBind: handler argument must be function');
      }
      model = this.model || this.collection;
      if (!model) return;
      this.modelBindings || (this.modelBindings = {});
      handlers = (_base = this.modelBindings)[type] || (_base[type] = []);
      if (_(handlers).include(handler)) return;
      handlers.push(handler);
      return model.bind(type, handler);
    };

    View.prototype.modelUnbind = function(type, handler) {
      var handlers, index, model;
      if (typeof type !== 'string') {
        throw new TypeError('View#modelUnbind: type argument must be string');
      }
      if (typeof handler !== 'function') {
        throw new TypeError('View#modelUnbind: handler argument must be function');
      }
      if (!this.modelBindings) return;
      handlers = this.modelBindings[type];
      if (handlers) {
        index = _(handlers).indexOf(handler);
        if (index > -1) handlers.splice(index, 1);
        if (handlers.length === 0) delete this.modelBindings[type];
      }
      model = this.model || this.collection;
      if (!model) return;
      return model.unbind(type, handler);
    };

    View.prototype.modelUnbindAll = function() {
      var handler, handlers, model, type, _i, _len, _ref;
      if (!this.modelBindings) return;
      model = this.model || this.collection;
      if (!model) return;
      _ref = this.modelBindings;
      for (type in _ref) {
        if (!__hasProp.call(_ref, type)) continue;
        handlers = _ref[type];
        for (_i = 0, _len = handlers.length; _i < _len; _i++) {
          handler = handlers[_i];
          model.unbind(type, handler);
        }
      }
      return this.modelBindings = null;
    };

    View.prototype.getTemplateData = function() {
      var modelAttributes, templateData,
        _this = this;
      modelAttributes = this.model && this.model.getAttributes();
      templateData = modelAttributes ? utils.beget(modelAttributes) : {};
      if (this.model && typeof this.model.state === 'function') {
        templateData.resolved = function() {
          return _this.model.state() === 'resolved';
        };
      }
      return templateData;
    };

    View.prototype.render = function() {
      var html, template;
      if (this.disposed) return;
      template = this.constructor.template;
      if (typeof template === 'string') {
        template = Handlebars.compile(template);
        this.constructor.template = template;
      }
      if (typeof template === 'function') {
        html = template(this.getTemplateData());
        this.$el.empty().append(html);
      }
      if (this.$container) this.$container.append(this.el);
      return this;
    };

    View.prototype.preventDefault = function(e) {
      if (e && e.preventDefault) return e.preventDefault();
    };

    View.prototype.disposed = false;

    View.prototype.dispose = function() {
      var prop, properties, _i, _len;
      if (this.disposed) return;
      this.modelUnbindAll();
      this.unsubscribeAllEvents();
      this.$el.remove();
      properties = 'el $el $container options model collection _callbacks'.split(' ');
      for (_i = 0, _len = properties.length; _i < _len; _i++) {
        prop = properties[_i];
        delete this[prop];
      }
      this.disposed = true;
      return typeof Object.freeze === "function" ? Object.freeze(this) : void 0;
    };

    return View;

  })(Backbone.View);
});
