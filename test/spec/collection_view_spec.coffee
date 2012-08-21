define [
  'underscore'
  'jquery'
  'chaplin/models/model'
  'chaplin/models/collection'
  'chaplin/views/view'
  'chaplin/views/collection_view'
], (_, jQuery, Model, Collection, View, CollectionView) ->
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
      expect(children.length).to.equal collection.length
      collection.each (model, index) ->
        $el = children.eq index

        expectedId = String model.id
        actualId = $el.attr('id')
        expect(actualId).to.equal expectedId

        expectedTitle = model.get('title')
        if expectedTitle?
          actualTitle = $el.text()
          expect(actualTitle).to.equal expectedTitle

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
      expect(_(visibleItems).isArray()).to.be.ok()
      expect(visibleItems.length).to.equal collection.length
      collection.each (model, index) ->
        expect(visibleItems[index]).to.equal model

    it 'should fire visibilityChange events', ->
      collection.reset()
      visibilityChange = sinon.spy()
      collectionView.on 'visibilityChange', visibilityChange
      addOne()
      expect(visibilityChange).was.calledWith collectionView.visibleItems
      expect(collectionView.visibleItems.length).to.equal 1

    it 'should add views when collection items are added', ->
      addThree()
      viewsMatchCollection()

    it 'should remove views when collection items are removed', ->
      models = addThree()
      collection.remove models
      viewsMatchCollection()

    it 'should remove all views when collection is emptied', ->
      collection.reset()
      children = getViewChildren()
      expect(children.length).to.equal 0

    it 'should reuse views on reset', ->
      model1 = collection.at 0
      view1 = collectionView.viewsByCid[model1.cid]
      expect(view1).to.be.a ItemView

      model2 = collection.at 1
      view2 = collectionView.viewsByCid[model2.cid]
      expect(view2).to.be.a ItemView

      collection.reset model1

      expect(view1.disposed).to.not.be.ok()
      expect(view2.disposed).to.be.ok()

      newView1 = collectionView.viewsByCid[model1.cid]
      expect(newView1).to.equal view1

    it 'should insert views in the right order', ->
      m0 = new Model id: 0
      m1 = new Model id: 1
      m2 = new Model id: 2
      m3 = new Model id: 3
      m4 = new Model id: 4
      m5 = new Model id: 5

      baseResetAndCheck = (setup, models) ->
        collection.reset setup
        collection.reset models
        viewsMatchCollection()

      makeResetAndCheck = (setup) ->
        (models) ->
          baseResetAndCheck setup, models

      full = [ m0, m1, m2, m3, m4, m5 ]

      # Removal tests
      resetAndCheck = makeResetAndCheck full
      # Remove first
      resetAndCheck [ m1, m2, m3, m4, m5 ]
      # Remove last
      resetAndCheck [ m0, m1, m2, m3, m4 ]
      # Remove two in the middle
      resetAndCheck [ m0, m1, m4, m5 ]
      # Remove every first
      resetAndCheck [ m1, m3, m5 ]
      # Remove every second
      resetAndCheck [ m0, m2, m4 ]

      # Addition tests
      resetAndCheck = makeResetAndCheck [ m1, m2, m3 ]
      # Add at the beginning
      resetAndCheck [ m0, m1, m2, m3 ]
      # Add at the end
      resetAndCheck [ m1, m2, m3, m4 ]
      # Add two in the middle
      baseResetAndCheck [ m0, m1, m4, m5 ], full
      # Add every first
      makeResetAndCheck [m1, m3, m5], full
      # Add every second
      makeResetAndCheck [m0, m2, m4], full

      # Addition/removal tests
      # Replace first
      baseResetAndCheck [ m0, m2, m3 ], [ m1, m2, m3 ]
      # Replace last
      baseResetAndCheck [ m0, m2, m5 ], [ m0, m3, m5 ]
      # Replace in the middle
      baseResetAndCheck [ m0, m2, m5 ], [ m0, m3, m5 ]
      # Change two in the middle
      baseResetAndCheck [ m0, m2, m3, m5 ], [ m0, m3, m4, m5 ]
      # Flip two in the middle
      baseResetAndCheck [ m0, m1, m2, m3 ], [ m0, m2, m1, m3 ]
      # Complete replacement
      baseResetAndCheck [ m0, m1, m2 ], [ m3, m4, m5 ]

    it 'should filter views', ->
      addThree()
      filterer = (model, position) ->
        expect(model).to.be.a Model
        expect(position).to.be.a 'number'
        model.get('title') is 'new'
      collectionView.filter filterer

      expect(collectionView.visibleItems.length).to.equal 3

      children = getViewChildren()
      expect(children.length).to.equal collection.length

      collection.each (model, index) ->
        $el = children.eq(index)
        visible = model.get('title') is 'new'
        displayValue = $el.css('display')
        if visible
          expect(displayValue).not.to.equal 'none'
        else
          expect(displayValue).to.equal 'none'

      collectionView.filter null
      expect(collectionView.visibleItems.length).to.equal collection.length

    it 'should dispose itself correctly', ->
      expect(collectionView.dispose).to.be.a 'function'
      model = collection.at 0
      viewsByCid = collectionView.viewsByCid

      expect(collectionView.disposed).to.not.be.ok()
      expect(view.disposed).to.not.be.ok() for cid, view of viewsByCid

      collectionView.dispose()
      expect(collectionView.disposed).to.be.ok()
      # All item views have been disposed, too
      expect(view.disposed).to.be.ok() for cid, view of viewsByCid

      for prop in ['viewsByCid', 'visibleItems']
        expect(_(collectionView).has prop).to.not.be.ok()

    it 'should initialize with a template', ->
      # Mix in SyncMachine into Collection
      collection.initSyncMachine()

      # Create a new CollectionView, dispose the old one
      collectionView.dispose()
      collectionView = new TemplatedCollectionView
        collection: collection

    it 'should render the template', ->
      children = getAllChildren()
      expect(children.length).to.equal 3

    it 'should append views to the listSelector', ->
      $list = collectionView.$list
      expect($list).to.be.a jQuery
      expect($list.length).to.equal 1

      $list2 = collectionView.$(collectionView.listSelector)
      expect($list.get(0) is $list2.get(0)).to.be.ok()

      children = getViewChildren()
      expect(children.length).to.equal collection.length

    it 'should set the fallback element properly', ->
      $fallback = collectionView.$fallback
      expect($fallback).to.be.a jQuery
      expect($fallback.length).to.equal 1

      $fallback2 = collectionView.$(collectionView.fallbackSelector)
      expect($fallback.get(0) is $fallback2.get(0)).to.be.ok()

    it 'should show the fallback element properly', ->
      $fallback = collectionView.$fallback

      # Filled + unsynced = not visible
      collection.unsync()
      expect($fallback.css('display')).to.equal 'none'

      # Filled + syncing = not visible
      collection.beginSync()
      expect($fallback.css('display')).to.equal 'none'

      # Filled + synced = not visible
      collection.finishSync()
      expect($fallback.css('display')).to.equal 'none'

      # Empty the list
      collection.reset()

      # Empty + unsynced = not visible
      collection.unsync()
      expect($fallback.css('display')).to.equal 'none'

      # Empty + syncing = not visible
      collection.beginSync()
      expect($fallback.css('display')).to.equal 'none'

      # Empty + synced = visible
      collection.finishSync()
      expect($fallback.css('display')).to.equal 'block'

      # Cross-check
      # Filled + synced = not visible
      addOne()
      expect($fallback.css('display')).to.equal 'none'

    it 'should set the loading indicator properly', ->
      $loading = collectionView.$loading
      expect($loading).to.be.a jQuery
      expect($loading.length).to.equal 1

      $loading2 = collectionView.$(collectionView.loadingSelector)
      expect($loading.get(0) is $loading.get(0)).to.be.ok()

    it 'should show the loading indicator properly', ->
      $loading = collectionView.$loading

      # Filled + unsynced = not visible
      collection.unsync()
      expect($loading.css('display')).to.equal 'none'

      # Filled + syncing = not visible
      collection.beginSync()
      expect($loading.css('display')).to.equal 'none'

      # Filled + synced = not visible
      collection.finishSync()
      expect($loading.css('display')).to.equal 'none'

      # Empty the list
      collection.reset()

      # Empty + unsynced = not visible
      collection.unsync()
      expect($loading.css('display')).to.equal 'none'

      # Empty + syncing = visible
      collection.beginSync()
      expect($loading.css('display')).to.equal 'block'

      # Empty + synced = not visible
      collection.finishSync()
      expect($loading.css('display')).to.equal 'none'

      # Cross-check
      # Filled + synced = not visible
      addOne()
      expect($loading.css('display')).to.equal 'none'

    it 'should also dispose when templated', ->
      collectionView.dispose()

      for prop in ['$list', '$fallback', '$loading']
        expect(_(collectionView).has prop).to.not.be.ok()

    it 'should respect the render and renderItems options', ->
      collectionView = new TemplatedCollectionView
        collection: collection
        render: false
        renderItems: false

      children = getAllChildren()
      expect(children.length).to.equal 0
      expect(_(collectionView).has '$list').to.not.be.ok()

      collectionView.render()
      children = getAllChildren()
      expect(children.length).to.equal 3
      expect(collectionView.$list).to.be.a jQuery
      expect(collectionView.$list.length).to.equal 1

      collectionView.renderAllItems()
      viewsMatchCollection()

    it 'should respect the filterer option', ->
      filterer = (model) -> model.id is 'A'
      collectionView.dispose()
      collectionView = new TemplatedCollectionView
        collection: collection
        filterer: filterer

      expect(collectionView.filterer).to.equal filterer
      expect(collectionView.visibleItems.length).to.equal 1

      children = getViewChildren()
      expect(children.length).to.equal collection.length

    it 'should respect the itemSelector property', ->
      collectionView.dispose()
      collectionView = new MixedCollectionView
        collection: collection

      additionalLength = 4
      allChildren = getAllChildren()
      expect(allChildren.length).to.equal collection.length + additionalLength
      viewChildren = getViewChildren()
      expect(viewChildren.length).to.equal collection.length

      expect(
        allChildren.eq(0).get(0) is viewChildren.get(0)
      ).to.not.be.ok()

      expect(
        allChildren.eq(additionalLength).get(0) is viewChildren.get(0)
      ).to.be.ok()

      collectionView.dispose()
