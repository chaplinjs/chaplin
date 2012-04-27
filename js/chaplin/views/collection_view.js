var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['jquery', 'underscore', 'lib/utils', 'chaplin/views/view'], function($, _, utils, View) {
  'use strict';
  var CollectionView;
  return CollectionView = (function(_super) {

    __extends(CollectionView, _super);

    function CollectionView() {
      this.renderAllItems = __bind(this.renderAllItems, this);
      this.showHideFallback = __bind(this.showHideFallback, this);
      this.itemsResetted = __bind(this.itemsResetted, this);
      this.itemRemoved = __bind(this.itemRemoved, this);
      this.itemAdded = __bind(this.itemAdded, this);
      CollectionView.__super__.constructor.apply(this, arguments);
    }

    CollectionView.prototype.animationDuration = 500;

    CollectionView.prototype.listSelector = null;

    CollectionView.prototype.$list = null;

    CollectionView.prototype.fallbackSelector = null;

    CollectionView.prototype.$fallback = null;

    CollectionView.prototype.loadingSelector = null;

    CollectionView.prototype.$loading = null;

    CollectionView.prototype.itemSelector = null;

    CollectionView.prototype.filterer = null;

    CollectionView.prototype.viewsByCid = null;

    CollectionView.prototype.visibleItems = null;

    CollectionView.prototype.getView = function(model) {
      throw new Error('CollectionView#getView must be overridden');
    };

    CollectionView.prototype.getTemplateFunction = function() {};

    CollectionView.prototype.initialize = function(options) {
      if (options == null) options = {};
      CollectionView.__super__.initialize.apply(this, arguments);
      /*console.debug 'CollectionView#initialize', this, @collection, options
      */
      _(options).defaults({
        render: true,
        renderItems: true,
        filterer: null
      });
      this.viewsByCid = {};
      this.visibleItems = [];
      /*
            @bind 'visibilityChange', (visibleItems) ->
              console.debug 'visibilityChange', visibleItems.length
            @modelBind 'syncStateChange', (collection, syncState) ->
              console.debug 'syncStateChange', syncState
      */
      this.addCollectionListeners();
      if (options.filterer) this.filter(options.filterer);
      if (options.render) this.render();
      if (options.renderItems) return this.renderAllItems();
    };

    CollectionView.prototype.addCollectionListeners = function() {
      this.modelBind('add', this.itemAdded);
      this.modelBind('remove', this.itemRemoved);
      return this.modelBind('reset', this.itemsResetted);
    };

    CollectionView.prototype.itemAdded = function(item, collection, options) {
      if (options == null) options = {};
      /*console.debug 'CollectionView#itemAdded', this, item.cid, item
      */
      return this.renderAndInsertItem(item, options.index);
    };

    CollectionView.prototype.itemRemoved = function(item) {
      /*console.debug 'CollectionView#itemRemoved', this, item.cid, item
      */      return this.removeViewForItem(item);
    };

    CollectionView.prototype.itemsResetted = function() {
      /*console.debug 'CollectionView#itemsResetted', this, @collection.length, @collection.models
      */      return this.renderAllItems();
    };

    CollectionView.prototype.render = function() {
      CollectionView.__super__.render.apply(this, arguments);
      /*console.debug 'CollectionView#render', this, @collection
      */
      this.$list = this.listSelector ? this.$(this.listSelector) : this.$el;
      this.initFallback();
      return this.initLoadingIndicator();
    };

    CollectionView.prototype.initFallback = function() {
      if (!this.fallbackSelector) return;
      /*console.debug 'CollectionView#initFallback', this, @el
      */
      this.$fallback = this.$(this.fallbackSelector);
      this.bind('visibilityChange', this.showHideFallback);
      return this.modelBind('syncStateChange', this.showHideFallback);
    };

    CollectionView.prototype.showHideFallback = function() {
      var visible;
      visible = this.visibleItems.length === 0 && (typeof this.collection.isSynced === 'function' ? this.collection.isSynced() : true);
      /*console.debug 'CollectionView#showHideFallback', this, 'visibleItems', @visibleItems.length, 'synced', @collection.isSynced?(), '\n\tvisible?', visible
      */
      return this.$fallback.css('display', visible ? 'block' : 'none');
    };

    CollectionView.prototype.collectionIsSynced = function() {};

    CollectionView.prototype.initLoadingIndicator = function() {
      if (!(this.loadingSelector && typeof this.collection.isSyncing === 'function')) {
        return;
      }
      this.$loading = this.$(this.loadingSelector);
      this.modelBind('syncStateChange', this.showHideLoadingIndicator);
      return this.showHideLoadingIndicator();
    };

    CollectionView.prototype.showHideLoadingIndicator = function() {
      var visible;
      visible = this.collection.length === 0 && this.collection.isSyncing();
      /*console.debug 'CollectionView#showHideLoadingIndicator', this, 'collection', @collection.length, 'syncing?', @collection.isSyncing(), '\n\tvisible?', visible
      */
      return this.$loading.css('display', visible ? 'block' : 'none');
    };

    CollectionView.prototype.filter = function(filterer) {
      /*console.debug 'CollectionView#filter', this, @collection
      */
      var included, index, item, view, _len, _ref;
      this.filterer = filterer;
      if (!_(this.viewsByCid).isEmpty()) {
        _ref = this.collection.models;
        for (index = 0, _len = _ref.length; index < _len; index++) {
          item = _ref[index];
          included = typeof filterer === 'function' ? filterer(item, index) : true;
          view = this.viewsByCid[item.cid];
          if (!view) {
            /*console.debug 'CollectionView#filter: no view for', item.cid, item
            */
            throw new Error('no view found for ' + item.cid);
            continue;
          }
          /*console.debug item, item.cid, view
          */
          view.$el.stop(true, true).css('display', included ? '' : 'none');
          this.updateVisibleItems(item, included, false);
        }
      }
      /*console.debug 'CollectionView#filter', 'visibleItems', @visibleItems.length
      */
      return this.trigger('visibilityChange', this.visibleItems);
    };

    CollectionView.prototype.renderAllItems = function() {
      var cid, index, item, items, remainingViewsByCid, view, _i, _len, _len2, _ref;
      items = this.collection.models;
      /*console.debug 'CollectionView#renderAllItems', items.length
      */
      this.visibleItems = [];
      remainingViewsByCid = {};
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        item = items[_i];
        view = this.viewsByCid[item.cid];
        if (view) {
          /*console.debug '\tview for', item.cid, 'remains'
          */
          remainingViewsByCid[item.cid] = view;
        }
      }
      _ref = this.viewsByCid;
      for (cid in _ref) {
        if (!__hasProp.call(_ref, cid)) continue;
        view = _ref[cid];
        /*console.debug '\tcheck', cid, view, 'remaining?', cid of remainingViewsByCid
        */
        if (!(cid in remainingViewsByCid)) {
          /*console.debug '\t\tremove view for', cid
          */
          this.removeView(cid, view);
        }
      }
      /*console.debug '\tbuild up list again'
      */
      for (index = 0, _len2 = items.length; index < _len2; index++) {
        item = items[index];
        view = this.viewsByCid[item.cid];
        if (view) {
          /*console.debug '\tre-insert', item.cid
          */
          this.insertView(item, view, index, 0);
        } else {
          /*console.debug '\trender and insert new view for', item.cid
          */
          this.renderAndInsertItem(item, index);
        }
      }
      if (!items.length) {
        /*console.debug 'CollectionView#renderAllItems', 'visibleItems', @visibleItems.length
        */
        return this.trigger('visibilityChange', this.visibleItems);
      }
    };

    CollectionView.prototype.renderAndInsertItem = function(item, index) {
      /*console.debug 'CollectionView#renderAndInsertItem', item.cid, item
      */
      var view;
      view = this.renderItem(item);
      return this.insertView(item, view, index);
    };

    CollectionView.prototype.renderItem = function(item) {
      /*console.debug 'CollectionView#renderItem', item.cid, item
      */
      var view;
      view = this.viewsByCid[item.cid];
      if (!view) {
        view = this.getView(item);
        this.viewsByCid[item.cid] = view;
      }
      view.render();
      return view;
    };

    CollectionView.prototype.insertView = function(item, view, index, animationDuration) {
      var $list, $next, $previous, $viewEl, children, included, length, position, viewEl;
      if (index == null) index = null;
      if (animationDuration == null) animationDuration = this.animationDuration;
      /*console.debug 'CollectionView#insertView', item, view, index
      */
      position = typeof index === 'number' ? index : this.collection.indexOf(item);
      /*console.debug '\titem', item.id, 'position', position, 'length', @collection.length
      */
      included = typeof this.filterer === 'function' ? this.filterer(item, position) : true;
      /*console.debug '\tincluded?', included
      */
      viewEl = view.el;
      $viewEl = view.$el;
      if (included) {
        if (animationDuration) $viewEl.css('opacity', 0);
      } else {
        $viewEl.css('display', 'none');
      }
      $list = this.$list;
      children = $list.children(this.itemSelector);
      length = children.length;
      /*console.debug '\tview', viewEl.id, 'position', position, 'children', length
      */
      if (length === 0 || position === length) {
        $list.append(viewEl);
      } else {
        if (position === 0) {
          $next = children.eq(position);
          $next.before(viewEl);
        } else {
          $previous = children.eq(position - 1);
          /*console.debug '\t\tinsert after', $previous.attr('id')
          */
          $previous.after(viewEl);
        }
      }
      view.trigger('addedToDOM');
      this.updateVisibleItems(item, included);
      if (animationDuration && included) {
        return $viewEl.animate({
          opacity: 1
        }, animationDuration);
      }
    };

    CollectionView.prototype.removeViewForItem = function(item) {
      /*console.debug 'CollectionView#removeViewForItem', this, item
      */
      var view;
      this.updateVisibleItems(item, false);
      view = this.viewsByCid[item.cid];
      return this.removeView(item.cid, view);
    };

    CollectionView.prototype.removeView = function(cid, view) {
      /*console.debug 'CollectionView#removeView', cid, view
      */      view.dispose();
      return delete this.viewsByCid[cid];
    };

    CollectionView.prototype.updateVisibleItems = function(item, includedInFilter, triggerEvent) {
      var includedInVisibleItems, visibilityChanged, visibleItemsIndex;
      if (triggerEvent == null) triggerEvent = true;
      visibilityChanged = false;
      visibleItemsIndex = _(this.visibleItems).indexOf(item);
      includedInVisibleItems = visibleItemsIndex > -1;
      /*console.debug 'CollectionView#updateVisibleItems', item.id, 'included?', includedInFilter
      */
      if (includedInFilter && !includedInVisibleItems) {
        this.visibleItems.push(item);
        visibilityChanged = true;
      } else if (!includedInFilter && includedInVisibleItems) {
        this.visibleItems.splice(visibleItemsIndex, 1);
        visibilityChanged = true;
      }
      /*console.debug '\tvisibilityChanged?', visibilityChanged, 'visibleItems', @visibleItems.length, 'triggerEvent?', triggerEvent
      */
      if (visibilityChanged && triggerEvent) {
        this.trigger('visibilityChange', this.visibleItems);
      }
      return visibilityChanged;
    };

    CollectionView.prototype.dispose = function() {
      /*console.debug 'CollectionView#dispose', this, 'disposed?', @disposed
      */
      var cid, prop, properties, view, _i, _len, _ref;
      if (this.disposed) return;
      this.collection.off(null, null, this);
      _ref = this.viewsByCid;
      for (cid in _ref) {
        if (!__hasProp.call(_ref, cid)) continue;
        view = _ref[cid];
        view.dispose();
      }
      properties = ['$list', '$fallback', '$loading', 'viewsByCid', 'visibleItems'];
      for (_i = 0, _len = properties.length; _i < _len; _i++) {
        prop = properties[_i];
        delete this[prop];
      }
      return CollectionView.__super__.dispose.apply(this, arguments);
    };

    return CollectionView;

  })(View);
});
