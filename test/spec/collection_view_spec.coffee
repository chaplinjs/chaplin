define [
  'underscore'
  'jquery'
  'chaplin/models/model'
  'chaplin/models/collection'
  'chaplin/views/view'
  'chaplin/views/collection_view'
  'chaplin/lib/sync_machine'
], (_, jQuery, Model, Collection, View, CollectionView, SyncMachine) ->
  'use strict'

  describe 'CollectionView', ->
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
      animationDuration: 0
      itemView: ItemView
      tagName: 'ul'

    # Testing class for a custom initItemView method
    class CustomViewCollectionView extends CollectionView
      tagName: 'ul'
      animationDuration: 0

      initItemView: (model) ->
        #console.debug 'TestCollectionView#initItemView', model
        new ItemView {model}

    # Testing class for insertino animation
    class AnimatingCollectionView extends CollectionView

      tagName: 'ul'

      animationDuration: 1

      itemView: ItemView

    # Testing class for CollectionViews with template,
    # custom list, loading indicator and fallback elements
    class TemplatedCollectionView extends TestCollectionView
      fallbackSelector: '> .fallback'
      listSelector: '> ol'
      loadingSelector: '> .loading'

      templateFunction: (templateData) ->
        """
        <h2>TemplatedCollectionView</h2>
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

    # Resets the collection with 26 models
    # with IDs A-Z and a random title
    fillCollection = ->
      models = for code in [65..90] # A-Z
        {
          id: String.fromCharCode(code)
          title: String(Math.random())
        }
      collection.reset models

    # Add one model with id: one and return it
    addOne = ->
      model = new Model id: 'one', title: 'one'
      collection.add model
      model

    # Add three models with id: new1-3 and return an array containing them
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
      expect(children.length).to.be collection.length
      collection.each (model, index) ->
        $el = children.eq index

        expectedId = String model.id
        actualId = $el.attr('id')
        expect(actualId).to.be expectedId

        expectedTitle = model.get('title')
        if expectedTitle?
          actualTitle = $el.text()
          expect(actualTitle).to.be expectedTitle

    # Create a fresh collection with models and
    # a collection view before each test
    beforeEach ->
      collection = new Collection()
      collectionView = new TestCollectionView {collection}
      fillCollection()

    afterEach ->
      collectionView.dispose()
      collection.dispose()
      collectionView = collection = null

    it 'should render item views', ->
      viewsMatchCollection()

    it 'should call a custom initItemView method', ->
      collectionView.dispose()
      initItemView = sinon.spy CustomViewCollectionView.prototype, 'initItemView'
      collectionView = new CustomViewCollectionView {collection}
      viewsMatchCollection()
      expect(initItemView.callCount).to.be collection.length
      initItemView.restore()

    it 'should init subviews with disabled autoRender', ->
      collectionView.dispose()
      calls = 0
      class AutoRenderItemView extends ItemView
        autoRender: true
        render: ->
          super
          calls += 1
      class AutoRenderCollectionView extends CollectionView
        itemView: AutoRenderItemView
      expect(calls).to.be 0
      collectionView = new AutoRenderCollectionView {collection}
      expect(calls).to.be collection.length

    it 'should have a visibleItems array', ->
      visibleItems = collectionView.visibleItems
      expect(visibleItems).to.be.an 'array'
      expect(visibleItems.length).to.be collection.length
      collection.each (model, index) ->
        expect(visibleItems[index]).to.be model

    it 'should fire visibilityChange events', ->
      collection.reset()
      visibilityChange = sinon.spy()
      collectionView.on 'visibilityChange', visibilityChange
      addOne()
      expect(visibilityChange).was.calledWith collectionView.visibleItems
      expect(collectionView.visibleItems.length).to.be 1

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
      expect(children.length).to.be 0

    it 'should reuse views on reset', ->
      expect(collectionView.getItemViews()).to.be.an 'object'

      model1 = collection.at 0
      view1 = collectionView.subview "itemView:#{model1.cid}"
      expect(view1).to.be.an ItemView

      model2 = collection.at 1
      view2 = collectionView.subview "itemView:#{model2.cid}"
      expect(view2).to.be.an ItemView

      collection.reset model1

      expect(view1.disposed).to.be false
      expect(view2.disposed).to.be true

      newView1 = collectionView.subview "itemView:#{model1.cid}"
      expect(newView1).to.be view1

    it 'should reorder views on sort', ->
      collection.reset addThree()

      sortAndMatch = (comparator) ->
        collection.comparator = comparator
        collection.sort()
        viewsMatchCollection()

      # Explicity force a default sort to ensure two different sort orderings
      sortAndMatch (a, b) -> a.id > b.id

      # Reverse the sort order and test it
      sortAndMatch (a, b) -> a.id < b.id

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

      full = [m0, m1, m2, m3, m4, m5]

      # Removal tests
      resetAndCheck = makeResetAndCheck full
      # Remove first
      resetAndCheck [m1, m2, m3, m4, m5]
      # Remove last
      resetAndCheck [m0, m1, m2, m3, m4]
      # Remove two in the middle
      resetAndCheck [m0, m1, m4, m5]
      # Remove every first
      resetAndCheck [m1, m3, m5]
      # Remove every second
      resetAndCheck [m0, m2, m4]

      # Addition tests
      resetAndCheck = makeResetAndCheck [m1, m2, m3]
      # Add at the beginning
      resetAndCheck [m0, m1, m2, m3]
      # Add at the end
      resetAndCheck [m1, m2, m3, m4]
      # Add two in the middle
      baseResetAndCheck [m0, m1, m4, m5], full
      # Add every first
      makeResetAndCheck [m1, m3, m5], full
      # Add every second
      makeResetAndCheck [m0, m2, m4], full

      # Addition/removal tests
      # Replace first
      baseResetAndCheck [m0, m2, m3], [m1, m2, m3]
      # Replace last
      baseResetAndCheck [m0, m2, m5], [m0, m3, m5]
      # Replace in the middle
      baseResetAndCheck [m0, m2, m5], [m0, m3, m5]
      # Change two in the middle
      baseResetAndCheck [m0, m2, m3, m5], [m0, m3, m4, m5]
      # Flip two in the middle
      baseResetAndCheck [m0, m1, m2, m3], [m0, m2, m1, m3]
      # Complete replacement
      baseResetAndCheck [m0, m1, m2], [m3, m4, m5]

    it 'should respect the autoRender and renderItems options', ->
      collectionView.dispose()

      renderSpy = sinon.spy CollectionView.prototype, 'render'
      renderAllItemsSpy = sinon.spy CollectionView.prototype, 'renderAllItems'

      collectionView = new TestCollectionView {
        collection,
        autoRender: false
        renderItems: false
      }

      expect(renderSpy).was.notCalled()
      expect(renderAllItemsSpy).was.notCalled()

      children = getAllChildren()
      expect(children.length).to.be 0
      expect(_.has collectionView, '$list').to.be false

      collectionView.render()
      expect(collectionView.$list).to.be.a jQuery
      expect(collectionView.$list.length).to.be 1

      collectionView.renderAllItems()
      viewsMatchCollection()

      renderSpy.restore()
      renderAllItemsSpy.restore()

    it 'should not return item data in getTemplateData', ->
      data = collectionView.getTemplateData()
      expect(data).to.eql {length: collection.length}

    it 'should animate the opacity of new items', ->
      $css = sinon.stub jQuery.prototype, 'css', -> this
      $animate = sinon.stub jQuery.prototype, 'animate', -> this

      collectionView.dispose()
      collectionView = new AnimatingCollectionView {collection}

      expect($css.callCount).to.be collection.length
      expect($css).was.calledWith 'opacity', 0

      expect($animate.callCount).to.be collection.length
      args = $animate.firstCall.args
      expect(args[0]).to.eql opacity: 1
      expect(args[1]).to.be collectionView.animationDuration

      expect($css.calledBefore($animate)).to.be true

      addThree()
      expect($css.callCount).to.be collection.length

      $css.restore()
      $animate.restore()

    it 'should not animate if animationDuration is 0', ->
      $css = sinon.spy jQuery.prototype, 'css'
      $animate = sinon.spy jQuery.prototype, 'animate'

      collectionView.dispose()
      collectionView = new TestCollectionView {collection}

      expect($css).was.notCalled()
      expect($animate).was.notCalled()

      addThree()
      expect($css).was.notCalled()
      expect($animate).was.notCalled()

      $css.restore()
      $animate.restore()

    it 'should not animate when re-inserting', ->
      $css = sinon.stub jQuery.prototype, 'css', -> this
      $animate = sinon.stub jQuery.prototype, 'animate', -> this

      model1 = new Model id: 1
      model2 = new Model id: 2
      model3 = new Model id: 3

      collection.reset [model1, model2]

      collectionView.dispose()
      collectionView = new AnimatingCollectionView {collection}

      expect($css).was.calledTwice()
      expect($animate).was.calledTwice()

      collection.reset [model1, model2, model3]

      expect($css.callCount).to.be collection.length
      expect($animate.callCount).to.be collection.length

      $css.restore()
      $animate.restore()

    it 'should animate with CSS classes', (done) ->
      collectionView.dispose()

      class AnimatingCollectionView extends CollectionView
        useCssAnimation: true
        itemView: ItemView

      collectionView = new AnimatingCollectionView {collection}
      children = getAllChildren()
      for child in children
        expect($(child).hasClass('animated-item-view')).to.be.true

      setTimeout ->
        for child in children
          expect($(child).hasClass('animated-item-view-end')).to.be.true
        done()
      , 1

    it 'should animate with custom CSS classes', (done) ->
      collectionView.dispose()

      class AnimatingCollectionView extends CollectionView
        useCssAnimation: true
        animationStartClass: 'a'
        animationEndClass: 'b'
        itemView: ItemView

      collectionView = new AnimatingCollectionView {collection}
      children = getAllChildren()
      for child in children
        expect($(child).hasClass('a')).to.be.true

      setTimeout ->
        for child in children
          expect($(child).hasClass('b')).to.be.true
        done()
      , 1

    it 'should dispose itself correctly', ->
      expect(collectionView.dispose).to.be.a 'function'
      model = collection.at 0
      viewsByCid = collectionView.getItemViews()

      expect(collectionView.disposed).to.be false
      for cid, view of viewsByCid
        expect(view.disposed).to.be false

      collectionView.dispose()
      expect(collectionView.disposed).to.be true
      # All item views have been disposed, too
      for cid, view of viewsByCid
        expect(view.disposed).to.be true

      for prop in ['visibleItems']
        expect(_.has collectionView, prop).to.be false

    describe 'Filtering', ->

      it 'should filter views using the filterer', ->
        addThree()
        filterer = sinon.spy (model, position) ->
          expect(model).to.be.a Model
          expect(position).to.be.a 'number'
          true
        collectionView.filter filterer
        expect(filterer.callCount).to.be collection.length

      it 'should hide filtered views per default', ->
        addThree()
        collectionView.filter (model) ->
          model.get('title') is 'new'

        children = getViewChildren()
        collection.each (model, index) ->
          $el = children.eq(index)
          visible = model.get('title') is 'new'
          displayValue = $el.css 'display'
          if visible
            expect(displayValue).not.to.be 'none'
          else
            expect(displayValue).to.be 'none'

      it 'should respect the filterer option', ->
        filterer = (model) -> model.id is 'A'
        collectionView.dispose()
        collectionView = new TestCollectionView {
          collection,
          filterer
        }

        expect(collectionView.filterer).to.be filterer
        expect(collectionView.visibleItems.length).to.be 1

        children = getViewChildren()
        expect(children.length).to.be collection.length

      it 'should remove the filter', ->
        addThree()
        collectionView.filter (model) ->
          model.get('title') is 'new'
        collectionView.filter null
        children = getViewChildren()
        children.each (index, element) ->
          displayValue = jQuery(element).css 'display'
          expect(displayValue).not.to.be 'none'
        expect(collectionView.visibleItems.length).to.be collection.length

      it 'should save the filterer', ->
        filterer = -> false
        collectionView.filter filterer
        expect(collectionView.filterer).to.be filterer
        collectionView.filter null
        expect(collectionView.filterer).to.be null

      it 'should trigger visibilityChange and update visibleItems when filtering', ->
        addThree()
        expect(collectionView.visibleItems.length).to.be collection.length

        visibilityChange = sinon.spy()
        collectionView.on 'visibilityChange', visibilityChange
        collectionView.filter (model) ->
          model.get('title') is 'new'

        expect(visibilityChange).was.calledOnce()
        args = visibilityChange.firstCall.args
        expect(args.length).to.be 1
        expect(args[0]).to.be collectionView.visibleItems
        expect(collectionView.visibleItems.length).to.be 3

        # Remove filter again
        collectionView.filter null
        expect(collectionView.visibleItems.length).to.be collection.length

    describe 'Filter callback', ->

      it 'should filter views with a callback', ->
        filterer = (model) ->
          model.get('title') is 'new'

        filterCallback = (view, included) ->
          view.$el.addClass(if included then 'included' else 'not-included')

        filterCallbackSpy = sinon.spy filterCallback
        collectionView.filter filterer, filterCallbackSpy

        expect(filterCallbackSpy.callCount).to.be collection.length

        checkCall = (model, call) ->
          view = collectionView.subview "itemView:#{model.cid}"
          included = filterer model
          expect(call.calledWith(view, included)).to.be true
          hasClass = view.$el.hasClass(
            if included then 'included' else 'not-included'
          )
          expect(hasClass).to.be true

        collection.each (model, index) ->
          call = filterCallbackSpy.getCall index
          checkCall model, call

        models = addThree()
        expect(filterCallbackSpy.callCount).to.be collection.length
        startIndex = 26
        for model, index in models
          call = filterCallbackSpy.getCall startIndex + index
          checkCall model, call

      it 'should save the filter callback', ->
        filterer = -> false
        filterCallback = ->
        expect(collectionView.filterCallback).to.be(
          CollectionView::filterCallback
        )
        collectionView.filter filterer, filterCallback
        expect(collectionView.filterCallback).to.be filterCallback

      it 'should not call the filter callback when unfiltered', ->
        collectionView.dispose()
        collection = new Collection()
        collectionView = new TestCollectionView {collection}
        spy = sinon.spy collectionView, 'filterCallback'
        fillCollection()
        addThree()
        expect(spy).was.notCalled()

    describe 'Templated CollectionView', ->

      beforeEach ->
        # Mix in SyncMachine into Collection
        _.extend collection, SyncMachine

        # Create a TemplatedCollectionView, dispose the standard one
        collectionView.dispose()
        collectionView = new TemplatedCollectionView {collection}

      it 'should render the template', ->
        children = getAllChildren()
        expect(children.length).to.be 4

      it 'should append views to the listSelector', ->
        $list = collectionView.$list
        expect($list).to.be.a jQuery
        expect($list.length).to.be 1

        $list2 = collectionView.$(collectionView.listSelector)
        expect($list.get(0)).to.be $list2.get(0)

        children = getViewChildren()
        expect(children.length).to.be collection.length

      it 'should set the fallback element properly', ->
        $fallback = collectionView.$fallback
        expect($fallback).to.be.a jQuery
        expect($fallback.length).to.be 1

        $fallback2 = collectionView.$(collectionView.fallbackSelector)
        expect($fallback.get(0)).to.be $fallback2.get(0)

      it 'should show the fallback element properly', ->
        $fallback = collectionView.$fallback

        # Filled + unsynced = not visible
        collection.unsync()
        expect($fallback.css('display')).to.be 'none'

        # Filled + syncing = not visible
        collection.beginSync()
        expect($fallback.css('display')).to.be 'none'

        # Filled + synced = not visible
        collection.finishSync()
        expect($fallback.css('display')).to.be 'none'

        # Empty the list
        collection.reset()

        # Empty + unsynced = not visible
        collection.unsync()
        expect($fallback.css('display')).to.be 'none'

        # Empty + syncing = not visible
        collection.beginSync()
        expect($fallback.css('display')).to.be 'none'

        # Empty + synced = visible
        collection.finishSync()
        expect($fallback.css('display')).to.be 'block'

        # Cross-check
        # Filled + synced = not visible
        addOne()
        expect($fallback.css('display')).to.be 'none'

      it 'should show fallback after filtering all items', ->
        collection.beginSync()
        collection.finishSync()
        filterer = (model) -> false
        collectionView.dispose()
        collectionView = new TemplatedCollectionView {collection, filterer}

        expect(collectionView.filterer).to.be filterer
        expect(collectionView.visibleItems.length).to.be 0
        expect(collectionView.$fallback.css('display')).to.be 'block'

      it 'should set the loading indicator properly', ->
        $loading = collectionView.$loading
        expect($loading).to.be.a jQuery
        expect($loading.length).to.be 1

        $loading2 = collectionView.$(collectionView.loadingSelector)
        expect($loading.get(0)).to.be $loading.get(0)

      it 'should show the loading indicator properly', ->
        $loading = collectionView.$loading

        # Filled + unsynced = not visible
        collection.unsync()
        expect($loading.css('display')).to.be 'none'

        # Filled + syncing = not visible
        collection.beginSync()
        expect($loading.css('display')).to.be 'none'

        # Filled + synced = not visible
        collection.finishSync()
        expect($loading.css('display')).to.be 'none'

        # Empty the list
        collection.reset()

        # Empty + unsynced = not visible
        collection.unsync()
        expect($loading.css('display')).to.be 'none'

        # Empty + syncing = visible
        collection.beginSync()
        expect($loading.css('display')).to.be 'block'

        # Empty + synced = not visible
        collection.finishSync()
        expect($loading.css('display')).to.be 'none'

        # Cross-check
        # Filled + synced = not visible
        addOne()
        expect($loading.css('display')).to.be 'none'

      it 'should pass sync status to template data', ->
        data = collectionView.getTemplateData()
        expect(data).to.eql {
          length: collection.length, synced: collection.isSynced()
        }

      it 'should also dispose when templated', ->
        collectionView.dispose()

        for prop in ['$list', '$fallback', '$loading']
          expect(_.has collectionView, prop).to.be false

      it 'should respect the itemSelector property', ->
        collectionView.dispose()
        collectionView = new MixedCollectionView {collection}

        additionalLength = 4
        allChildren = getAllChildren()
        expect(allChildren.length).to.be collection.length + additionalLength
        viewChildren = getViewChildren()
        expect(viewChildren.length).to.be collection.length

        # The first element is not an item view
        expect(allChildren.eq(0).get(0)).to.not.be viewChildren.get(0)
        # The item views are append after the existing elements
        expect(allChildren.eq(additionalLength).get(0)).to.be viewChildren.get(0)

    # End TemplatedCollectionView spec

