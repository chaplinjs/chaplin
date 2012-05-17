define [
  'jquery'
  'chaplin/models/model'
  'chaplin/models/collection'
  'chaplin/views/view'
  'chaplin/views/collection_view'
], (jQuery, Model, Collection, View, CollectionView) ->
  'use strict'

  describe 'CollectionView', ->
    #console.debug 'CollectionView spec'

    # Initialize shared variables
    collection = collectionView = null

    # Test view classes
    # -----------------

    # Item view class
    class ItemView extends View

      tagName: 'li'

      initialize: ->
        super
        @$el.attr
          id: @model.id
          cid: @model.cid

      templateFunction: (templateData) ->
        templateData.title

      getTemplateFunction: ->
        @templateFunction

    # Main CollectionView testing class
    class TestCollectionView extends CollectionView

      tagName: 'ul'

      animationDuration: 0

      getView: (model) ->
        #console.debug 'TestCollectionView#getView', model
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

    # Testing class for a CollectionView with non-view children
    class MixedCollectionView extends TestCollectionView
      itemSelector: 'li'

      templateFunction: (templateData) ->
        """
        <p>foo</p>
        <div>bar</div>
        <article>qux</article>
        <ul>
          <li>nested</li>
        </ul>
        """

      getTemplateFunction: ->
        @templateFunction

    # Helper functions

    fillCollection = ->
      models = for code in [65..90] # A-Z
        {
          id: String.fromCharCode(code)
          title: String(Math.random())
        }
      collection.reset models

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

    getViewChildren = ->
      collectionView.$list.children collectionView.itemSelector

    getAllChildren = ->
      collectionView.$el.children()

    viewsMatchCollection = ->
      children = getViewChildren()
      expect(children.length).toBe collection.length
      collection.each (model, index) ->
        expected = model.id
        actual = children.eq(index).attr('id')
        expect(actual).toBe expected

    # Create the collection
    collection = new Collection()

    # Fill the collection with models before each test
    beforeEach ->
      fillCollection()

    it 'should initialize', ->
      collectionView = new TestCollectionView
        collection: collection

    it 'should render item views', ->
      viewsMatchCollection()

    it 'should have a visibleItems array', ->
      visibleItems = collectionView.visibleItems
      expect(_(visibleItems).isArray()).toBe true
      expect(visibleItems.length).toBe collection.length
      collection.each (model, index) ->
        expect(visibleItems[index]).toBe model

    it 'should fire visibilityChange events', ->
      collection.reset()
      visibilityChange = jasmine.createSpy()
      collectionView.on 'visibilityChange', visibilityChange
      addOne()
      expect(visibilityChange).toHaveBeenCalledWith collectionView.visibleItems
      expect(collectionView.visibleItems.length).toBe 1

    it 'should add views when collection items are added', ->
      [model1, model2, model3] = addThree()

      children = getViewChildren()

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
      viewsMatchCollection()

    it 'should remove all views when collection is emptied', ->
      collection.reset()
      children = getViewChildren()
      expect(children.length).toBe 0

    it 'should reuse views on reset', ->
      model1 = collection.at 0
      view1 = collectionView.viewsByCid[model1.cid]
      expect(view1 instanceof ItemView).toBe true

      model2 = collection.at 1
      view2 = collectionView.viewsByCid[model2.cid]
      expect(view2 instanceof ItemView).toBe true

      collection.reset model1

      expect(view1.disposed).toBe false
      expect(view2.disposed).toBe true

      newView1 = collectionView.viewsByCid[model1.cid]
      expect(newView1).toBe view1

    it 'should append views in the right order', ->
      collection.comparator = (model) -> model.id
      collection.reset {id: '2'}
      collection.addAtomic [
        {id: '0'}
        {id: '1'}
        {id: '3'}
        {id: '4'}
      ]
      viewsMatchCollection()
      delete collection.comparator

    it 'should filter views', ->
      addThree()
      filterer = (model, position) ->
        expect(model instanceof Model).toBe true
        expect(typeof position).toBe 'number'
        model.get('title') is 'new'
      collectionView.filter filterer

      expect(collectionView.visibleItems.length).toBe 3

      children = getViewChildren()
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

    it 'should be disposable and dispose all item views', ->
      expect(typeof collectionView.dispose).toBe 'function'
      model = collection.at 0
      viewsByCid = collectionView.viewsByCid

      expect(collectionView.disposed).toBe false
      expect(view.disposed).toBe false for cid, view of viewsByCid
      collectionView.dispose()
      expect(collectionView.disposed).toBe true
      expect(view.disposed).toBe true for cid, view of viewsByCid

      expect(collectionView.viewsByCid).toBe null
      expect(collectionView.visibleItems).toBe null

    it 'should initialize with a template', ->
      # Mix in SyncMachine into Collection
      collection.initSyncMachine()

      # Create a new CollectionView, dispose the old one
      collectionView.dispose()
      collectionView = new TemplatedCollectionView
        collection: collection

    it 'should render the template', ->
      children = getAllChildren()
      expect(children.length).toBe 3

    it 'should append views to the listSelector', ->
      $list = collectionView.$list
      expect($list instanceof jQuery).toBe true
      expect($list.length).toBe 1

      $list2 = collectionView.$(collectionView.listSelector)
      expect($list.get(0) is $list2.get(0)).toBe true

      children = getViewChildren()
      expect(children.length).toBe collection.length

    it 'should set the fallback element properly', ->
      $fallback = collectionView.$fallback
      expect($fallback instanceof jQuery).toBe true
      expect($fallback.length).toBe 1

      $fallback2 = collectionView.$(collectionView.fallbackSelector)
      expect($fallback.get(0) is $fallback2.get(0)).toBe true

    it 'should show the fallback element properly', ->
      $fallback = collectionView.$fallback

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

    it 'should set the loading indicator properly', ->
      $loading = collectionView.$loading
      expect($loading instanceof jQuery).toBe true
      expect($loading.length).toBe 1

      $loading2 = collectionView.$(collectionView.loadingSelector)
      expect($loading.get(0) is $loading.get(0)).toBe true

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

    it 'should respect the render options', ->
      collectionView = new TemplatedCollectionView
        collection: collection
        render: false
        renderItems: false

      children = getAllChildren()
      expect(children.length).toBe 0
      expect(collectionView.$list).toBe null

      collectionView.render()
      children = getAllChildren()
      expect(children.length).toBe 3
      expect(collectionView.$list instanceof jQuery).toBe true
      expect(collectionView.$list.length).toBe 1

      collectionView.renderAllItems()
      viewsMatchCollection()

    it 'should respect the filterer option', ->
      filterer = (model) -> model.id is 'A'
      collectionView.dispose()
      collectionView = new TemplatedCollectionView
        collection: collection
        filterer: filterer

      expect(collectionView.filterer).toBe filterer
      expect(collectionView.visibleItems.length).toBe 1

      children = getViewChildren()
      expect(children.length).toBe collection.length

    it 'should respect the itemSelector property', ->
      collectionView.dispose()
      collectionView = new MixedCollectionView
        collection: collection

      additionalLength = 4
      allChildren = getAllChildren()
      expect(allChildren.length).toBe collection.length + additionalLength
      viewChildren = getViewChildren()
      expect(viewChildren.length).toBe collection.length

      expect(
        allChildren.eq(0).get(0) is viewChildren.get(0)
      ).toBe false

      expect(
        allChildren.eq(additionalLength).get(0) is viewChildren.get(0)
      ).toBe true

      collectionView.dispose()
