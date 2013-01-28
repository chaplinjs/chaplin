// Generated by CoffeeScript 1.4.0
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

define(['jquery', 'underscore', 'backbone', 'chaplin/lib/utils', 'chaplin/lib/event_broker', 'chaplin/models/model', 'chaplin/models/collection'], function($, _, Backbone, utils, EventBroker, Model, Collection) {
  'use strict';

  var View;
  return View = (function(_super) {

    __extends(View, _super);

    _(View.prototype).extend(EventBroker);

    View.prototype.autoRender = false;

    View.prototype.container = null;

    View.prototype.containerMethod = 'append';

    View.prototype.subviews = null;

    View.prototype.subviewsByName = null;

    View.prototype.wrapMethod = function(name) {
      var func, instance;
      instance = this;
      func = instance[name];
      instance["" + name + "IsWrapped"] = true;
      return instance[name] = function() {
        if (this.disposed) {
          return false;
        }
        func.apply(instance, arguments);
        instance["after" + (utils.upcase(name))].apply(instance, arguments);
        return instance;
      };
    };

    function View() {
      if (this.initialize !== View.prototype.initialize) {
        this.wrapMethod('initialize');
      }
      if (this.render !== View.prototype.render) {
        this.wrapMethod('render');
      } else {
        this.render = _(this.render).bind(this);
      }
      View.__super__.constructor.apply(this, arguments);
    }

    View.prototype.initialize = function(options) {
      var prop, _i, _len, _ref;
      if (options) {
        _ref = ['autoRender', 'container', 'containerMethod'];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          prop = _ref[_i];
          if (options[prop] != null) {
            this[prop] = options[prop];
          }
        }
      }
      this.subviews = [];
      this.subviewsByName = {};
      if (this.model || this.collection) {
        this.modelBind('dispose', this.dispose);
      }
      if (!this.initializeIsWrapped) {
        return this.afterInitialize();
      }
    };

    View.prototype.afterInitialize = function() {
      if (this.autoRender) {
        return this.render();
      }
    };

    View.prototype.delegate = function(eventType, second, third) {
      var event, events, handler, list, selector;
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
      list = (function() {
        var _i, _len, _ref, _results;
        _ref = eventType.split(' ');
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          event = _ref[_i];
          _results.push("" + event + ".delegate" + this.cid);
        }
        return _results;
      }).call(this);
      events = list.join(' ');
      handler = _(handler).bind(this);
      if (selector) {
        this.$el.on(events, selector, handler);
      } else {
        this.$el.on(events, handler);
      }
      return handler;
    };

    View.prototype.undelegate = function() {
      return this.$el.unbind(".delegate" + this.cid);
    };

    View.prototype.modelBind = function(type, handler) {
      var modelOrCollection;
      if (typeof type !== 'string') {
        throw new TypeError('View#modelBind: ' + 'type must be a string');
      }
      if (typeof handler !== 'function') {
        throw new TypeError('View#modelBind: ' + 'handler argument must be function');
      }
      modelOrCollection = this.model || this.collection;
      if (!modelOrCollection) {
        throw new TypeError('View#modelBind: no model or collection set');
      }
      modelOrCollection.off(type, handler, this);
      return modelOrCollection.on(type, handler, this);
    };

    View.prototype.modelUnbind = function(type, handler) {
      var modelOrCollection;
      if (typeof type !== 'string') {
        throw new TypeError('View#modelUnbind: ' + 'type argument must be a string');
      }
      if (typeof handler !== 'function') {
        throw new TypeError('View#modelUnbind: ' + 'handler argument must be a function');
      }
      modelOrCollection = this.model || this.collection;
      if (!modelOrCollection) {
        return;
      }
      return modelOrCollection.off(type, handler);
    };

    View.prototype.modelUnbindAll = function() {
      var modelOrCollection;
      modelOrCollection = this.model || this.collection;
      if (!modelOrCollection) {
        return;
      }
      return modelOrCollection.off(null, null, this);
    };

    View.prototype.pass = function(attribute, selector) {
      var _this = this;
      return this.modelBind("change:" + attribute, function(model, value) {
        var $el;
        $el = _this.$(selector);
        if ($el.is('input, textarea, select, button')) {
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
      if (!nameOrView) {
        return;
      }
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
      if (!(name && view && view.dispose)) {
        return;
      }
      view.dispose();
      index = _(this.subviews).indexOf(view);
      if (index > -1) {
        this.subviews.splice(index, 1);
      }
      return delete this.subviewsByName[name];
    };

    View.prototype.getTemplateData = function() {
      var items, model, modelOrCollection, templateData, _i, _len, _ref;
      if (this.model) {
        templateData = this.model instanceof Model ? this.model.serialize() : utils.beget(this.model.attributes);
      } else if (this.collection) {
        if (this.collection instanceof Collection) {
          items = this.collection.serialize();
        } else {
          items = [];
          _ref = this.collection.models;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            model = _ref[_i];
            items.push(utils.beget(model.attributes));
          }
        }
        templateData = {
          items: items
        };
      } else {
        templateData = {};
      }
      modelOrCollection = this.model || this.collection;
      if (modelOrCollection) {
        if (typeof modelOrCollection.state === 'function' && !('resolved' in templateData)) {
          templateData.resolved = modelOrCollection.state() === 'resolved';
        }
        if (typeof modelOrCollection.isSynced === 'function' && !('synced' in templateData)) {
          templateData.synced = modelOrCollection.isSynced();
        }
      }
      return templateData;
    };

    View.prototype.getTemplateFunction = function() {
      throw new Error('View#getTemplateFunction must be overridden');
    };

    View.prototype.render = function() {
      var html, templateFunc;
      if (this.disposed) {
        return false;
      }
      templateFunc = this.getTemplateFunction();
      if (typeof templateFunc === 'function') {
        html = templateFunc(this.getTemplateData());
        this.$el.empty().append(html);
      }
      if (!this.renderIsWrapped) {
        this.afterRender();
      }
      return this;
    };

    View.prototype.afterRender = function() {
      if (this.container) {
        $(this.container)[this.containerMethod](this.el);
        return this.trigger('addedToDOM');
      }
    };

    View.prototype.disposed = false;

    View.prototype.dispose = function() {
      var prop, properties, subview, _i, _j, _len, _len1, _ref;
      if (this.disposed) {
        return;
      }
      if (this.subviews) {
        _ref = this.subviews;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          subview = _ref[_i];
          subview.dispose();
        }
      }
      this.unsubscribeAllEvents();
      this.modelUnbindAll();
      this.off();
      this.$el.remove();
      properties = ['el', '$el', 'options', 'model', 'collection', 'subviews', 'subviewsByName', '_callbacks'];
      for (_j = 0, _len1 = properties.length; _j < _len1; _j++) {
        prop = properties[_j];
        delete this[prop];
      }
      this.disposed = true;
      return typeof Object.freeze === "function" ? Object.freeze(this) : void 0;
    };

    return View;

  })(Backbone.View);
});