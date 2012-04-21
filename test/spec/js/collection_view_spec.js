var __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['chaplin/models/model', 'chaplin/models/collection', 'chaplin/views/view', 'chaplin/views/collection_view'], function(Model, Collection, View, CollectionView) {
  'use strict';  return describe('CollectionView', function() {
    var ItemView, TestCollectionView, code, collection, collectionView, models;
    console.debug('CollectionView spec');
    collectionView = void 0;
    ItemView = (function(_super) {

      __extends(ItemView, _super);

      function ItemView() {
        ItemView.__super__.constructor.apply(this, arguments);
      }

      ItemView.prototype.tagName = 'li';

      ItemView.prototype.templateFunction = function(templateData) {
        return templateData.title;
      };

      ItemView.prototype.getTemplateFunction = function() {
        return this.templateFunction;
      };

      return ItemView;

    })(View);
    TestCollectionView = (function(_super) {

      __extends(TestCollectionView, _super);

      function TestCollectionView() {
        TestCollectionView.__super__.constructor.apply(this, arguments);
      }

      TestCollectionView.prototype.tagName = 'ul';

      TestCollectionView.prototype.templateFunction = function(templateData) {
        return templateData.title;
      };

      TestCollectionView.prototype.getTemplateFunction = function() {
        return this.templateFunction;
      };

      TestCollectionView.prototype.getView = function(item) {
        return new ItemView(item);
      };

      return TestCollectionView;

    })(CollectionView);
    models = (function() {
      var _results;
      _results = [];
      for (code = 65; code <= 90; code++) {
        _results.push(new Model({
          id: String.fromCharCode(code)
        }));
      }
      return _results;
    })();
    collection = new Collection(models);
    it('should initialize', function() {
      return collectionView = new TestCollectionView({
        collection: collection
      });
    });
    it('should render item views', function() {
      return expect(collectionView.$el.children().length).toBe(models.length);
    });
    return xit('should be tested more thoroughly', function() {
      return expect(false).toBe(true);
    });
  });
});
