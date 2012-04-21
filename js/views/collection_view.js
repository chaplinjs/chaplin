var __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['views/view', 'chaplin/views/collection_view'], function(View, ChaplinCollectionView) {
  'use strict';
  var CollectionView;
  return CollectionView = (function(_super) {

    __extends(CollectionView, _super);

    function CollectionView() {
      CollectionView.__super__.constructor.apply(this, arguments);
    }

    CollectionView.prototype.getTemplateFunction = View.prototype.getTemplateFunction;

    return CollectionView;

  })(ChaplinCollectionView);
});
