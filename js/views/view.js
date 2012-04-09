var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['lib/utils', 'lib/subscriber', 'lib/view_helper'], function(utils, Subscriber) {
  'use strict';
  var View;
  return View = (function(_super) {

    __extends(View, _super);

    _(View.prototype).extend(Subscriber);

    View.prototype.autoRender = false;

    View.prototype.containerSelector = null;

    View.prototype.containerMethod = 'append';

    View.prototype.$container = null;

    View.prototype.subviews = null;

    View.prototype.subviewsByName = null;

    function View() {
      this.dispose = __bind(this.dispose, this);
      this.render = __bind(this.render, this);
      var wrapMethod,
        _this = this;
      wrapMethod = function(name) {
        var func;
        func = _this[name];
        return _this[name] = function() {
          func.apply(_this, arguments);
          return _this["after" + (utils.upcase(name))].apply(_this, arguments);
        };
      };
      wrapMethod('initialize');
      wrapMethod('render');
      View.__super__.constructor.apply(this, arguments);
    }

    View.prototype.initialize = function(options) {
      this.subviews = [];
      this.subviewsByName = {};
      if (this.model || this.collection) this.modelBind('dispose', this.dispose);
      if (options && options.container) {
        return this.$container = $(container);
      } else if (this.containerSelector) {
        return this.$container = $(this.containerSelector);
      }
    };

    View.prototype.afterInitialize = function(options) {
      var byDefault, byOption;
      byOption = options && options.autoRender === true;
      byDefault = this.autoRender && !byOption;
      if (byOption || byDefault) return this.render();
    };

    View.prototype.delegateEvents = function() {};

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
        throw new TypeError('View#delegate: only two or three arguments are\
allowed');
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

    View.prototype._modelBindings = null;

    View.prototype.modelBind = function(type, handler) {
      var handlers, model, _base;
      if (typeof type !== 'string') {
        throw new TypeError('View#modelBind: type must be string');
      }
      if (typeof handler !== 'function') {
        throw new TypeError('View#modelBind: handler must be function');
      }
      model = this.model || this.collection;
      if (!model) {
        throw new TypeError('View#modelBind: no model or collection set');
      }
      this._modelBindings || (this._modelBindings = {});
      handlers = (_base = this._modelBindings)[type] || (_base[type] = []);
      if (_(handlers).include(handler)) return;
      handlers.push(handler);
      return model.on(type, handler, this);
    };

    View.prototype.modelUnbind = function(type, handler) {
      var handlers, index, model;
      if (typeof type !== 'string') {
        throw new TypeError('View#modelUnbind: type must be string');
      }
      if (typeof handler !== 'function') {
        throw new TypeError('View#modelUnbind: handler must be function');
      }
      if (!this._modelBindings) return;
      handlers = this._modelBindings[type];
      if (handlers) {
        index = _(handlers).indexOf(handler);
        if (index > -1) handlers.splice(index, 1);
        if (handlers.length === 0) delete this._modelBindings[type];
      }
      model = this.model || this.collection;
      if (!model) return;
      return model.off(type, handler);
    };

    View.prototype.modelUnbindAll = function() {
      var model;
      this._modelBindings = null;
      model = this.model || this.collection;
      if (!model) return;
      return model.off(null, null, this);
    };

    View.prototype.pass = function(eventType, selector) {
      var model,
        _this = this;
      model = this.model || this.collection;
      return this.modelBind(eventType, function(model, val) {
        return _this.$(selector).html(val);
      });
    };

    View.prototype.subview = function(name, view) {
      if (name && view) {
        this.removeSubview(name);
        this.subviews.push(view);
        this.subviewsByName[name] = view;
        return view;
      } else if (name) {
        return this.subviewsByName[name];
      }
    };

    View.prototype.removeSubview = function(nameOrView) {
      var index, name, otherName, otherView, view, _ref;
      if (!nameOrView) return;
      if (typeof nameOrView === 'string') {
        name = nameOrView;
        view = this.subviewsByName[name];
      } else {
        view = nameOrView;
        _ref = this.subviewsByName;
        for (otherName in _ref) {
          otherView = _ref[otherName];
          if (view === otherView) {
            name = otherName;
            break;
          }
        }
      }
      if (!(name && view && view.dispose)) return;
      view.dispose();
      index = _(this.subviews).indexOf(view);
      if (index > -1) this.subviews.splice(index, 1);
      return delete this.subviewsByName[name];
    };

    View.prototype.getTemplateData = function() {
      var modelAttributes, templateData;
      modelAttributes = this.model && this.model.getAttributes();
      templateData = modelAttributes ? utils.beget(modelAttributes) : {};
      if (this.model && typeof this.model.state === 'function') {
        templateData.resolved = this.model.state() === 'resolved';
      }
      return templateData;
    };

    View.prototype.render = function() {
      var html, template;
      if (this.disposed) return;
      template = this.template;
      if (typeof template === 'string') {
        template = Handlebars.compile(template);
        this.template = template;
      }
      if (typeof template === 'function') {
        html = template(this.getTemplateData());
        this.$el.empty().append(html);
      }
      return this;
    };

    View.prototype.afterRender = function() {
      if (this.$container && (this.$container[this.containerMethod] != null)) {
        this.$container[this.containerMethod](this.el);
        this.trigger('addedToDOM');
      }
      return this;
    };

    View.prototype.disposed = false;

    View.prototype.dispose = function() {
      var prop, properties, view, _i, _j, _len, _len2, _ref;
      if (this.disposed) return;
      _ref = this.subviews;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        view = _ref[_i];
        view.dispose();
      }
      this.unsubscribeAllEvents();
      this.modelUnbindAll();
      this.off();
      this.$el.remove();
      properties = ['el', '$el', '$container', 'options', 'model', 'collection', 'subviews', 'subviewsByName'];
      for (_j = 0, _len2 = properties.length; _j < _len2; _j++) {
        prop = properties[_j];
        delete this[prop];
      }
      this.disposed = true;
      return typeof Object.freeze === "function" ? Object.freeze(this) : void 0;
    };

    return View;

  })(Backbone.View);
});
