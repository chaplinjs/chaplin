define [
  'chaplin/models/model',
  'chaplin/models/collection',
  'chaplin/views/view',
  'chaplin/views/collection_view',
], (Model, Collection, View, CollectionView) ->
  'use strict'

  describe 'CollectionView', ->
    console.debug 'CollectionView spec'

    collectionView = undefined

    # Test view classes

    class ItemView extends View
      tagName: 'li'
      templateFunction: (templateData) ->
        templateData.title
      getTemplateFunction: ->
        @templateFunction

    class TestCollectionView extends CollectionView
      tagName: 'ul'
      templateFunction: (templateData) ->
        templateData.title
      getTemplateFunction: ->
        @templateFunction
      getView: (item) ->
        new ItemView item

    # Create test collection
    models = for code in [65..90]
      new Model id: String.fromCharCode(code)
    collection = new Collection models

    it 'should initialize', ->
      collectionView = new TestCollectionView
        collection: collection

    it 'should render item views', ->
      #console.debug 'items', collectionView.$el.children()
      expect(collectionView.$el.children().length).toBe models.length

    xit 'should be tested more thoroughly', ->
      expect(false).toBe true
