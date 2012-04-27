var __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['jquery', 'underscore', 'backbone', 'chaplin/lib/utils', 'chaplin/lib/subscriber'], function($, _, Backbone, utils, Subscriber) {
  'use strict';
  var View;
  return View = (function(_super) {
    var wrapMethod;

    __extends(View, _super);

    _(View.prototype).extend(Subscriber);

    View.prototype.autoRender = false;

    View.prototype.containerSelector = null;

    View.prototype.containerMethod = 'append';

    View.prototype.subviews = null;

    View.prototype.subviewsByName = null;

    wrapMethod = function(obj, name) {
      var func;
      func = obj[name];
      return obj[name] = function() {
        func.apply(obj, arguments);
        return obj["after" + (utils.upcase(name))].apply(obj, arguments);
      };
    };

    function View() {
      if (this.initialize !== View.prototype.initialize) {
        wrapMethod(this, 'initialize');
      }
      if (this.initialize !== View.prototype.initialize) {
        wrapMethod(this, 'render');
      } else {
        this.render = _(this.render).bind(this);
      }
      View.__super__.constructor.apply(this, arguments);
    }

    View.prototype.initialize = function(options) {
      /*console.debug 'View#initialize', this, 'options', options
      */      this.subviews = [];
      this.subviewsByName = {};
      if (this.model || this.collection) this.modelBind('dispose', this.dispose);
      if (this.initialize === View.prototype.initialize) {
        return this.afterInitialize();
      }
    };

    View.prototype.afterInitialize = function() {
      var autoRender;
      autoRender = this.options.autoRender != null ? this.options.autoRender : this.autoRender;
      if (autoRender) return this.render();
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
          throw new TypeError('View#delegate: ' + 'second argument must be a string');
        }
        handler = third;
      } else {
        throw new TypeError('View#delegate: ' + 'only two or three arguments are allowed');
      }
      if (typeof handler !== 'function') {
        throw new TypeError('View#delegate: ' + 'handler argument must be function');
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
      var model;
      if (typeof type !== 'string') {
        throw new TypeError('View#modelBind: ' + 'type must be a string');
      }
      if (typeof handler !== 'function') {
        throw new TypeError('View#modelBind: ' + 'handler argument must be function');
      }
      model = this.model || this.collection;
      if (!model) {
        throw new TypeError('View#modelBind: no model or collection set');
      }
      model.off(type, handler, this);
      return model.on(type, handler, this);
    };

    View.prototype.modelUnbind = function(type, handler) {
      var model;
      if (typeof type !== 'string') {
        throw new TypeError('View#modelUnbind: ' + 'type argument must be a string');
      }
      if (typeof handler !== 'function') {
        throw new TypeError('View#modelUnbind: ' + 'handler argument must be a function');
      }
      model = this.model || this.collection;
      if (!model) return;
      return model.off(type, handler);
    };

    View.prototype.modelUnbindAll = function() {
      var model;
      model = this.model || this.collection;
      if (!model) return;
      return model.off(null, null, this);
    };

    View.prototype.pass = function(attribute, selector) {
      var _this = this;
      return this.modelBind("change:" + attribute, function(model, value) {
        var $el;
        $el = _this.$(selector);
        if ($el.is(':input')) {
          return $el.val(value);
        } else {
          return $el.text(value);
        }
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

    View.prototype.getTemplateFunction = function() {
      throw new Error('View#getTemplateFunction must be overridden');
    };

    View.prototype.render = function() {
      /*console.debug 'View#render', this
      */
      var html, templateData, templateFunc;
      if (this.disposed) return;
      templateData = this.getTemplateData();
      templateFunc = this.getTemplateFunction();
      if (typeof templateFunc === 'function') {
        html = templateFunc(templateData);
        this.$el.empty().append(html);
      }
      return this;
    };

    View.prototype.afterRender = function() {
      var container, containerMethod;
      container = this.options.container != null ? this.options.container : this.containerSelector;
      if (container) {
        containerMethod = this.options.containerMethod != null ? this.options.containerMethod : this.containerMethod;
        $(container)[containerMethod](this.el);
        this.trigger('addedToDOM');
      }
      return this;
    };

    View.prototype.disposed = false;

    View.prototype.dispose = function() {
      /*console.debug 'View#dispose', this, 'disposed?', @disposed
      */
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
      properties = ['el', '$el', 'options', 'model', 'collection', 'subviews', 'subviewsByName', '_callbacks'];
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
