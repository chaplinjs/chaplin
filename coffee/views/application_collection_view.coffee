define [
  'views/application_view',
  'chaplin/views/collection_view'
], (ApplicationView, ChaplinCollectionView) ->
  'use strict'

  class ApplicationCollectionView extends ChaplinCollectionView

    # Borrow the method from the View prototype
    getTemplateFunction: ApplicationView::getTemplateFunction
