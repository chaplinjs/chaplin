define [
  'jquery',
  'chaplin/models/model',
  'chaplin/models/collection',
  'chaplin/views/view',
  'chaplin/views/collection_view',
], (jQuery, Model, Collection, View, CollectionView) ->
  'use strict'

  describe 'CollectionView', ->
    #console.debug 'CollectionView spec'

    collection = collectionView = undefined

    # Test view classes
    # -----------------

    # Item view class
    class ItemView extends View

      tagName: 'li'

      initialize: ->
        super
        @el.id = @model.id

      templateFunction: (templateData) ->
        templateData.title

      getTemplateFunction: ->
        @templateFunction

    # Main CollectionView testing class
    class TestCollectionView extends CollectionView

      tagName: 'ul'

      animationDuration: 0

      getView: (model) ->
        new ItemView model: model

    # Testing class for CollectionViews with template,
    # custom list, loading indicator and fallback elements
    class TemplatedCollectionView extends TestCollectionView

      listSelector: '> ol'
      fallbackSelector: '> .fallback'
      loadingSelector: '> .loading'

      templateFunction: (templateData) ->
        """
        <ol></ol>
        <p class="loading">Loading…</p>
        <p class="fallback">This list is empty.</p>
        """

      getTemplateFunction: ->
        @templateFunction

    # Helper function

    getModels = ->
      models = for code in [65..90] # A-Z
        new Model
          id: String.fromCharCode(code)
          title: String(Math.random())

    fillCollection = ->
      collection.reset getModels()

    addOne = ->
      model = new Model id: 'one', title: 'one'
      collection.add model
      model

    addThree = ->
      model1 = new Model id: 'new1', title: 'new'
      model2 = new Model id: 'new2', title: 'new'
      model3 = new Model id: 'new3', title: 'new'
      collection.add model1, at: 0
      collection.add model2, at: 10
      collection.add model3
      [model1, model2, model3]

    # Create the collection
    collection = new Collection()

    # Fill the collection with models before each test
    beforeEach ->
      fillCollection()

    it 'should initialize', ->
      collectionView = new TestCollectionView
        collection: collection

    it 'should render item views', ->
      children = collectionView.$el.children()
      expect(children.length).toBe collection.length
      collection.each (model, index) ->
        expected = model.id
        actual = children.eq(index).attr('id')
        expect(actual).toBe expected

    it 'should have a visibleItems array', ->
      visibleItems = collectionView.visibleItems
      expect(_(visibleItems).isArray()).toBe true
      expect(visibleItems.length).toBe collection.length
      collection.each (model, index) ->
        expect(visibleItems[index]).toBe model

    it 'should fire visibilityChange events', ->
      collection.reset()
      spy = jasmine.createSpy()
      collectionView.on 'visibilityChange', spy
      addOne()
      expect(spy).toHaveBeenCalledWith collectionView.visibleItems
      expect(collectionView.visibleItems.length).toBe 1

    it 'should add views when collection items are added', ->
      [model1, model2, model3] = addThree()

      children = collectionView.$el.children()

      first = children.first()
      expect(first.attr('id')).toBe model1.id
      expect(first.text()).toBe model1.get('title')

      tenth = children.eq 10
      expect(tenth.attr('id')).toBe model2.id
      expect(tenth.text()).toBe model2.get('title')

      last = children.last()
      expect(last.attr('id')).toBe model3.id
      expect(last.text()).toBe model3.get('title')

    it 'should remove views when collection items are removed', ->
      models = addThree()
      collection.remove models

      children = collectionView.$el.children()
      expect(children.length).toBe collection.length
      collection.each (model, index) ->
        expected = model.id
        actual = children.eq(index).attr('id')
        expect(actual).toBe expected

    it 'should remove all views when collection is emptied', ->
      collection.reset()
      children = collectionView.$el.children()
      expect(children.length).toBe 0

    it 'should reuse views on reset', ->
      model1 = collection.at 0
      view1 = collectionView.viewsByCid[model1.cid]
      expect(view1 instanceof ItemView).toBe true

      model2 = collection.at 1
      view2 = collectionView.viewsByCid[model2.cid]
      expect(view2 instanceof ItemView).toBe true

      collection.reset [model1]

      expect(view1.disposed).toBe false
      expect(view2.disposed).toBe true

      newView1 = collectionView.viewsByCid[model1.cid]
      expect(newView1).toBe view1

    it 'should filter views', ->
      addThree()
      filterer = (model, position) ->
        expect(model instanceof Model).toBe true
        expect(typeof position).toBe 'number'
        model.get('title') is 'new'
      collectionView.filter filterer

      expect(collectionView.visibleItems.length).toBe 3

      children = collectionView.$el.children()
      expect(children.length).toBe collection.length

      collection.each (model, index) ->
        $el = children.eq(index)
        visible = model.get('title') is 'new'
        displayValue = $el.css('display')
        if visible
          expect(displayValue).not.toBe 'none'
        else
          expect(displayValue).toBe 'none'

      collectionView.filter null
      expect(collectionView.visibleItems.length).toBe collection.length

    it 'should be disposable', ->
      expect(typeof collectionView.dispose).toBe 'function'
      model = collection.at 0
      view = collectionView.viewsByCid[model.cid]
      expect(view instanceof ItemView).toBe true

      expect(collectionView.disposed).toBe false
      expect(view.disposed).toBe false
      collectionView.dispose()
      expect(collectionView.disposed).toBe true
      expect(view.disposed).toBe true

      expect(view.viewsByCid).toBe undefined
      expect(view.visibleItems).toBe undefined

    it 'should initialize with a template', ->
      # Mix in SyncMachine into Collection
      collection.initSyncMachine()

      # Create a new CollectionView, dispose the old one
      collectionView.dispose()
      collectionView = new TemplatedCollectionView
        collection: collection

    it 'should render templates', ->
      children = collectionView.$el.children()
      expect(children.length).toBe 3

      $list = collectionView.$(collectionView.listSelector)
      $fallback = collectionView.$(collectionView.fallbackSelector)
      $loading = collectionView.$(collectionView.loadingSelector)

      expect($list.length).toBe 1
      expect($fallback.length).toBe 1
      expect($loading.length).toBe 1

    it 'should apply selector properties', ->
      $list = collectionView.$list
      $fallback = collectionView.$fallback
      $loading = collectionView.$loading

      expect($list instanceof jQuery).toBe true
      expect($fallback instanceof jQuery).toBe true
      expect($loading instanceof jQuery).toBe true

      expect($list.length).toBe 1
      expect($fallback.length).toBe 1
      expect($loading.length).toBe 1

    it 'should append item views to the listSelector', ->
      $list = collectionView.$(collectionView.listSelector)
      children = $list.children()
      expect(children.length).toBe collection.length

    it 'should show the fallback element properly', ->
      $fallback = collectionView.$(collectionView.fallbackSelector)

      # Filled + unsynced = not visible
      collection.unsync()
      expect($fallback.css('display')).toBe 'none'

      # Filled + syncing = not visible
      collection.beginSync()
      expect($fallback.css('display')).toBe 'none'

      # Filled + synced = not visible
      collection.finishSync()
      expect($fallback.css('display')).toBe 'none'

      # Empty the list
      collection.reset()

      # Empty + unsynced = not visible
      collection.unsync()
      expect($fallback.css('display')).toBe 'none'

      # Empty + syncing = not visible
      collection.beginSync()
      expect($fallback.css('display')).toBe 'none'

      # Empty + synced = visible
      collection.finishSync()
      expect($fallback.css('display')).toBe 'block'

      # Cross-check
      # Filled + synced = not visible
      addOne()
      expect($fallback.css('display')).toBe 'none'

    it 'should show the loading indicator properly', ->
      $loading = collectionView.$loading

      # Filled + unsynced = not visible
      collection.unsync()
      expect($loading.css('display')).toBe 'none'

      # Filled + syncing = not visible
      collection.beginSync()
      expect($loading.css('display')).toBe 'none'

      # Filled + synced = not visible
      collection.finishSync()
      expect($loading.css('display')).toBe 'none'

      # Empty the list
      collection.reset()

      # Empty + unsynced = not visible
      collection.unsync()
      expect($loading.css('display')).toBe 'none'

      # Empty + syncing = visible
      collection.beginSync()
      expect($loading.css('display')).toBe 'block'

      # Empty + synced = not visible
      collection.finishSync()
      expect($loading.css('display')).toBe 'none'

      # Cross-check
      # Filled + synced = not visible
      addOne()
      expect($loading.css('display')).toBe 'none'

    it 'should also dispose when templated', ->
      collectionView.dispose()

      expect(collectionView.$list).toBe null
      expect(collectionView.$fallback).toBe null
      expect(collectionView.$loading).toBe null
