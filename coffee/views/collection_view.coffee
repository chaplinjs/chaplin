define [
  'views/view',
  'chaplin/views/collection_view'
], (View, ChaplinCollectionView) ->
  'use strict'

  class CollectionView extends ChaplinCollectionView

    # Borrow the method from the View prototype
    getTemplateFunction: View::getTemplateFunction
