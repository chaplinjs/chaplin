'use strict'

$ = require 'jquery'

sinon = require 'sinon'
chai = require 'chai'
chai.use require 'sinon-chai'
chai.should()

{expect} = require 'chai'
{SyncMachine, utils, Collection, Model} = require '../src/chaplin'
{CollectionView, View} = require '../src/chaplin'

describe 'CollectionView', ->
  # Initialize shared variables
  collection = null
  collectionView = null

  # Main test classes
  # -----------------

  # Item view class
  class ItemView extends View
    tagName: 'li'

    initialize: ->
      super
      @el.setAttribute 'id', @model.id
      @el.setAttribute 'cid', @model.cid

    templateFunction: (templateData) ->
      templateData.title

    getTemplateFunction: ->
      @templateFunction

  # Main CollectionView testing class
  class TestCollectionView extends CollectionView
    tagName: 'ul'
    animationDuration: 0
    itemView: ItemView

  # Create 26 objects with IDs A-Z and a random title
  freshModels = ->
    for code in [65..90] # A-Z
      id: String.fromCharCode code
      title: String Math.random()

  # Add one model with id: one and return it
  addOne = ->
    model = new Model id: 'one', title: 'one'
    collection.add model
    model

  threeModels = ->
    model1 = new Model id: 'new1', title: 'new'
    model2 = new Model id: 'new2', title: 'new'
    model3 = new Model id: 'new3', title: 'new'
    [model1, model2, model3]

  # Add three models with id: new1-3 and return an array containing them
  addThree = ->
    models = threeModels()
    collection.add models[0], at: 0
    collection.add models[1], at: 10
    collection.add models[2]
    models

  getViewChildren = ->
    if $
      collectionView.$list.children collectionView.itemSelector
    else
      if collectionView.itemSelector
        (item for item in collectionView.list.children when utils.matchesSelector item, collectionView.itemSelector)
      else
        collectionView.list.children

  getAllChildren = ->
    if $
      collectionView.$el.children()
    else
      collectionView.el.children

  viewsMatchCollection = ->
    children = getViewChildren()
    expect(children).have.lengthOf collection.length
    collection.forEach (model, index) ->
      el = children[index]

      expectedId = String model.id
      actualId = el.id
      expect(actualId).to.equal expectedId

      expectedTitle = model.get 'title'
      if expectedTitle?
        actualTitle = el.textContent
        expect(actualTitle).to.equal expectedTitle

  createCollection = (models) ->
    collection = new Collection models or freshModels()

  createCollectionView = ->
    collectionView = new TestCollectionView {collection}

  basicSetup = (models) ->
    createCollection models
    createCollectionView()

  afterEach ->
    collectionView?.dispose()
    collection?.dispose()
    collectionView = collection = null

  describe 'Basic item rendering', ->

    it 'should render item views', ->
      basicSetup()
      viewsMatchCollection()

    it 'should call a custom initItemView method', ->

      class CustomCollectionView extends CollectionView
        tagName: 'ul'
        animationDuration: 0
        initItemView: (model) ->
          #console.debug 'TestCollectionView#initItemView', model
          new ItemView {model}

      createCollection()
      initItemView = sinon.spy CustomCollectionView.prototype, 'initItemView'
      collectionView = new CustomCollectionView {collection}
      viewsMatchCollection()
      expect(initItemView.callCount).to.equal collection.length
      initItemView.restore()

    it 'should respect the autoRender and renderItems options', ->
      createCollection()

      renderSpy = sinon.spy CollectionView.prototype, 'render'
      renderAllItemsSpy = sinon.spy CollectionView.prototype, 'renderAllItems'

      collectionView = new TestCollectionView {
        collection,
        autoRender: false
        renderItems: false
      }

      renderSpy.should.not.have.been.called
      renderAllItemsSpy.should.not.have.been.called

      children = getAllChildren()
      expect(children).to.have.lengthOf 0
      expect(collectionView).not.to.have.ownProperty '$list'

      collectionView.render()
      if $
        expect(collectionView.$list).to.be.an.instanceof $
        expect(collectionView.$list).to.have.lengthOf 1
      else
        expect(collectionView.list).to.be.an.instanceof Element

      collectionView.renderAllItems()
      viewsMatchCollection()

      renderSpy.restore()
      renderAllItemsSpy.restore()

    it 'should init subviews with disabled autoRender', ->
      calls = 0

      class AutoRenderItemView extends ItemView
        autoRender: false
        render: ->
          super
          calls += 1

      class AutoRenderCollectionView extends CollectionView
        itemView: AutoRenderItemView

      createCollection()
      collectionView = new AutoRenderCollectionView {collection}
      expect(calls).to.equal collection.length

  describe 'Basic collection change behavior', ->

    it 'should add views when collection items are added', ->
      basicSetup()
      addThree()
      viewsMatchCollection()

    it 'should remove views when collection items are removed', ->
      basicSetup()
      models = addThree()
      collection.remove models
      viewsMatchCollection()

    it 'should remove all views when collection is emptied', ->
      basicSetup()
      collection.reset()
      children = getViewChildren()
      expect(children.length).to.equal 0

  describe 'Sorting', ->

    it 'should reorder views on sort', ->
      basicSetup threeModels()

      sortAndMatch = (comparator) ->
        collection.comparator = comparator
        collection.sort()
        viewsMatchCollection()

      # Explicity force a default sort to ensure two different sort orderings
      sortAndMatch (a, b) -> a.id > b.id

      # Reverse the sort order and test it
      sortAndMatch (a, b) -> a.id < b.id

  describe 'Complex Reset and Set behavior', ->

    it 'should reuse views on reset', ->
      basicSetup()
      expect(collectionView.getItemViews()).to.be.an 'object'

      model1 = collection.at 0
      view1 = collectionView.subview "itemView:#{model1.cid}"
      expect(view1).to.be.an.instanceof ItemView

      model2 = collection.at 1
      view2 = collectionView.subview "itemView:#{model2.cid}"
      expect(view2).to.be.an.instanceof ItemView

      collection.reset model1

      expect(view1.disposed).to.be.false
      expect(view2.disposed).to.be.true

      newView1 = collectionView.subview "itemView:#{model1.cid}"
      expect(newView1).to.equal view1

    it 'should insert views in the right order on reset', ->
      basicSetup()

      m0 = new Model id: 0
      m1 = new Model id: 1
      m2 = new Model id: 2
      m3 = new Model id: 3
      m4 = new Model id: 4
      m5 = new Model id: 5

      baseResetAndCheck = (models1, models2) ->
        collection.reset models1
        collection.reset models2
        viewsMatchCollection()

      makeResetAndCheck = (models1) ->
        (models2) ->
          baseResetAndCheck models1, models2

      full = [m0, m1, m2, m3, m4, m5]

      # Removal tests from a full collection

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
      baseResetAndCheck [m1, m3, m5], full
      # Add every second
      baseResetAndCheck [m0, m2, m4], full

      # Addition and removal tests

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

    it 'should insert views in the right order on set', ->
      basicSetup()

      m0 = new Model id: 0
      m1 = new Model id: 1
      m2 = new Model id: 2
      m3 = new Model id: 3
      m4 = new Model id: 4
      m5 = new Model id: 5

      baseSetAndCheck = (models1, models2) ->
        collection.reset models1
        collection.set models2
        viewsMatchCollection()

      makeSetAndCheck = (setup) ->
        (models) ->
          baseSetAndCheck setup, models

      full = [m0, m1, m2, m3, m4, m5]

      # Removal tests from a full collection

      setAndCheck = makeSetAndCheck full
      # Remove first
      setAndCheck [m1, m2, m3, m4, m5]
      # Remove last
      setAndCheck [m0, m1, m2, m3, m4]
      # Remove two in the middle
      setAndCheck [m0, m1, m4, m5]
      # Remove every first
      setAndCheck [m1, m3, m5]
      # Remove every second
      setAndCheck [m0, m2, m4]

      # Addition tests

      setAndCheck = makeSetAndCheck [m1, m2, m3]
      # Add at the beginning
      setAndCheck [m0, m1, m2, m3]
      # Add at the end
      setAndCheck [m1, m2, m3, m4]
      # Add two in the middle
      baseSetAndCheck [m0, m1, m4, m5], full
      # Add every first
      baseSetAndCheck [m1, m3, m5], full
      # Add every second
      baseSetAndCheck [m0, m2, m4], full

      # Addition and removal tests

      # Replace first
      baseSetAndCheck [m0, m2, m3], [m1, m2, m3]
      # Replace last
      baseSetAndCheck [m0, m2, m5], [m0, m3, m5]
      # Replace in the middle
      baseSetAndCheck [m0, m2, m5], [m0, m3, m5]
      # Change two in the middle
      baseSetAndCheck [m0, m2, m3, m5], [m0, m3, m4, m5]
      # Flip two in the middle
      baseSetAndCheck [m0, m1, m2, m3], [m0, m2, m1, m3]
      # Complete replacement
      baseSetAndCheck [m0, m1, m2], [m3, m4, m5]

  describe 'Visible items', ->

    it 'should have a visibleItems array', ->
      basicSetup()
      visibleItems = collectionView.visibleItems
      expect(visibleItems).to.be.an 'array'
      expect(visibleItems).to.have.lengthOf collection.length
      collection.forEach (model, index) ->
        expect(visibleItems[index]).to.equal model

    it 'should fire visibilityChange events', ->
      basicSetup []
      visibilityChange = sinon.spy()
      collectionView.on 'visibilityChange', visibilityChange
      addOne()
      {visibleItems} = collectionView
      visibilityChange.should.have.been.calledWith visibleItems
      expect(visibleItems).to.have.lengthOf 1

  describe 'Animation', ->

    class AnimatingCollectionView extends CollectionView
      tagName: 'ul'
      animationDuration: 1
      itemView: ItemView

    it 'should animate the opacity of new items', ->
      return unless $

      $css = sinon.stub($.fn, 'css').callsFake -> this
      $animate = sinon.stub($.fn, 'animate').callsFake -> this

      createCollection()
      collectionView = new AnimatingCollectionView {collection}

      expect($css.callCount).to.equal collection.length
      $css.should.have.been.calledWith 'opacity', 0

      expect($animate.callCount).to.equal collection.length
      {args} = $animate.firstCall
      expect(args[0]).to.deep.equal opacity: 1
      expect(args[1]).to.equal collectionView.animationDuration

      expect($css.calledBefore($animate)).to.be.true

      addThree()
      expect($css.callCount).to.equal collection.length

      $css.restore()
      $animate.restore()

    it 'should not animate if animationDuration is 0', ->
      return unless $

      $css = sinon.spy $.fn, 'css'
      $animate = sinon.spy $.fn, 'animate'

      createCollection()
      collectionView = new TestCollectionView {collection}

      $css.should.not.have.been.called
      $animate.should.not.have.been.called

      addThree()

      $css.should.not.have.been.called
      $animate.should.not.have.been.called

      $css.restore()
      $animate.restore()

    it 'should not animate when re-inserting', ->
      return unless $

      $css = sinon.stub($.fn, 'css').callsFake -> this
      $animate = sinon.stub($.fn, 'animate').callsFake -> this

      model1 = new Model id: 1
      model2 = new Model id: 2
      model3 = new Model id: 3

      createCollection [model1, model2]
      collectionView = new AnimatingCollectionView {collection}

      $css.should.have.been.calledTwice
      $animate.should.have.been.calledTwice

      collection.reset [model1, model2, model3]

      expect($css.callCount).to.equal collection.length
      expect($animate.callCount).to.equal collection.length

      $css.restore()
      $animate.restore()

    it 'should animate with CSS classes', (done) ->

      class AnimatingCollectionView extends CollectionView
        useCssAnimation: true
        itemView: ItemView

      createCollection()
      collectionView = new AnimatingCollectionView {collection}

      children = getAllChildren()
      for child in children
        expect(child.className).to.match /animated-item-view/

      setTimeout ->
        for child in children
          expect(child.className).to.match /animated-item-view-end/
        done()

    it 'should animate with custom CSS classes', (done) ->

      class AnimatingCollectionView extends CollectionView
        useCssAnimation: true
        animationStartClass: 'a'
        animationEndClass: 'b'
        itemView: ItemView

      createCollection()
      collectionView = new AnimatingCollectionView {collection}

      children = getAllChildren()
      for child in children
        expect(child.className).to.match /a/

      setTimeout ->
        for child in children
          expect(child.className).to.match /b/
        done()

  describe 'Filtering', ->

    it 'should filter views using the filterer', ->
      basicSetup()
      filterer = sinon.spy (model, position) ->
        expect(model).to.be.an.instanceof Model
        expect(this).to.equal collectionView
        expect(position).to.be.a 'number'
        true
      collectionView.filter filterer
      expect(collection).to.have.lengthOf filterer.callCount

    it 'should not set filterer to non-function', ->
      basicSetup()
      filterer = collectionView.filterer = sinon.spy -> true
      collectionView.filter()
      expect(collection).to.have.lengthOf filterer.callCount

    it 'should hide filtered views per default', ->
      basicSetup()
      addThree()

      collectionView.filter (model) ->
        model.get('title') is 'new'

      children = getViewChildren()
      collection.forEach (model, index) ->
        el = children[index]
        visible = model.get('title') is 'new'
        displayValue = el.style.display
        if visible
          expect(displayValue).not.to.eq 'none'
        else
          expect(displayValue).to.eq 'none'

    it 'should respect the filterer option', ->
      createCollection()

      filterer = (model) -> model.id is 'A'
      items = collection.where id: 'A'
      collectionView = new TestCollectionView {
        collection,
        filterer
      }

      expect(collectionView.filterer).to.equal filterer
      expect(collectionView.visibleItems).to.have.lengthOf 1

      children = getViewChildren()
      expect(children).to.have.lengthOf items.length

    it 'should remove the filter', ->
      basicSetup()
      addThree()

      collectionView.filter (model) ->
        model.get('title') is 'new'
      collectionView.filter null

      children = getViewChildren()
      for element in children
        if $
          displayValue = $(element).css 'display'
          expect(displayValue).not.to.equal 'none'
        else
          displayValue = element.style.display
          expect(displayValue).not.to.equal 'none'

      expect(collectionView.visibleItems).to.have.lengthOf collection.length

    it 'should save the filterer', ->
      basicSetup()

      filterer = -> false
      collectionView.filter filterer
      expect(collectionView.filterer).to.equal filterer

      collectionView.filter null
      expect(collectionView.filterer).to.be.null

    it 'should trigger visibilityChange and update visibleItems', ->
      basicSetup()
      addThree()
      expect(collectionView.visibleItems).to.have.lengthOf collection.length

      visibilityChange = sinon.spy()
      collectionView.on 'visibilityChange', visibilityChange
      collectionView.filter (model) ->
        model.get('title') is 'new'

      visibilityChange.should.have.been.calledOnce
      {args} = visibilityChange.firstCall
      expect(args).to.have.lengthOf 1
      expect(args[0]).to.equal collectionView.visibleItems
      expect(collectionView.visibleItems).to.have.lengthOf 3

      # Remove filter again
      collectionView.filter null
      expect(collectionView.visibleItems).to.have.lengthOf collection.length

  describe 'Filter callback', ->

    it 'should filter views with a callback', ->
      basicSetup()

      filterer = (model) ->
        model.get('title') is 'new'

      filterCallback = (view, included) ->
        cls = if included then 'included' else 'not-included'
        if $
          view.$el.addClass cls
        else
          view.el.classList.add cls

      filterCallbackSpy = sinon.spy filterCallback
      collectionView.filter filterer, filterCallbackSpy

      expect(collection).to.have.lengthOf filterCallbackSpy.callCount

      checkCall = (model, call) ->
        view = collectionView.subview "itemView:#{model.cid}"
        included = filterer model
        call.should.have.been.calledWith view, included
        hasClass = view.el.className.indexOf(
          if included then 'included' else 'not-included'
        ) isnt -1
        expect(hasClass).to.be.true

      collection.forEach (model, index) ->
        call = filterCallbackSpy.getCall index
        checkCall model, call

      models = addThree()
      expect(collection).to.have.lengthOf filterCallbackSpy.callCount
      startIndex = 26
      for model, index in models
        call = filterCallbackSpy.getCall startIndex + index
        checkCall model, call
      return

    it 'should save the filter callback', ->
      basicSetup()

      filterer = -> false
      filterCallback = ->
      expect(collectionView.filterCallback).to.equal(
        CollectionView::filterCallback
      )
      collectionView.filter filterer, filterCallback
      expect(collectionView.filterCallback).to.equal filterCallback

    it 'should not call the filter callback when unfiltered', ->
      createCollection []
      collectionView = new TestCollectionView {collection}

      spy = sinon.spy collectionView, 'filterCallback'
      collection.reset freshModels()
      addThree()
      spy.should.not.have.been.called

  describe 'Disposal', ->

    it 'should dispose itself correctly', ->
      basicSetup()

      expect(collectionView.dispose).to.be.a 'function'
      viewsByCid = collectionView.getItemViews()

      expect(collectionView.disposed).to.be.false
      for cid, view of viewsByCid
        expect(view.disposed).to.be.false

      collectionView.dispose()
      expect(collectionView.disposed).to.be.true
      # All item views have been disposed, too
      for cid, view of viewsByCid
        expect(view.disposed).to.be.true

      collectionView.should.not.have.ownProperty 'visibleItems'

  describe 'Templated CollectionView', ->

    # Testing class for CollectionViews with template,
    # custom list, loading indicator and fallback elements
    class TemplatedCollectionView extends TestCollectionView
      fallbackSelector: '.fallback'
      listSelector: 'ol'
      loadingSelector: '.loading'
      getTemplateFunction: ->
        ->
          """
          <h2>TemplatedCollectionView</h2>
          <ol></ol>
          <p class="loading">Loading…</p>
          <p class="fallback">This list is empty.</p>
          """

    beforeEach ->
      createCollection()
      # Mix in SyncMachine into Collection
      Object.assign collection, SyncMachine

      collectionView = new TemplatedCollectionView {collection}

    describe 'Template rendering', ->

      it 'should render the template', ->
        children = getAllChildren()
        expect(children).to.have.lengthOf 4

      it 'should pass the length and the sync status to the template', ->
        data = collectionView.getTemplateData()
        expect(data).to.deep.equal
          length: collection.length,
          synced: collection.isSynced()

    describe 'Selectors', ->

      it 'should append views to the listSelector', ->
        if $
          $list = collectionView.$list
          expect($list).to.be.an.instanceof $
          expect($list).to.have.lengthOf 1

          $list2 = collectionView.$(collectionView.listSelector)
          expect($list[0]).to.equal $list2[0]

          children = getViewChildren()
          expect(children).to.have.lengthOf collection.length
        else
          list = collectionView.list
          expect(list).to.be.an.instanceof HTMLElement

          list2 = collectionView.el.querySelector collectionView.listSelector
          expect(list).to.equal list2

          children = getViewChildren()
          expect(children).to.have.lengthOf collection.length

      it 'should respect the itemSelector property', ->

        # A CollectionView class with non-view child elements
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

        collectionView.dispose()
        collectionView = new MixedCollectionView {collection}

        addLength = 4
        allChildren = getAllChildren()
        expect(allChildren).to.have.lengthOf collection.length + addLength
        viewChildren = getViewChildren()
        expect(viewChildren).to.have.lengthOf collection.length

        # The first element is not an item view
        expect(allChildren[0]).to.not.equal viewChildren[0]
        # The item views are append after the existing elements
        expect(allChildren[addLength]).to.equal viewChildren[0]

    describe 'Fallback element', ->

      it 'should set the fallback element properly', ->
        if $
          {$fallback} = collectionView
          expect($fallback).to.be.an.instanceof $
          expect($fallback).to.have.lengthOf 1

          $fallback2 = collectionView.find collectionView.fallbackSelector
          expect($fallback[0]).to.equal $fallback2[0]
        else
          {fallback} = collectionView
          expect(fallback).to.be.an.instanceof HTMLElement
          fallback2 = collectionView.find collectionView.fallbackSelector
          expect(fallback).to.equal fallback2

      it 'should show the fallback element properly', ->
        fallback = if $
          collectionView.$fallback[0]
        else
          collectionView.fallback

        expectVisible = ->
          expect(fallback.style.display).to.equal if $ then 'block' else ''

        expectInvisible = ->
          expect(fallback.style.display).to.equal 'none'

        # Filled + unsynced = not visible
        collection.unsync()
        expectInvisible()

        # Filled + syncing = not visible
        collection.beginSync()
        expectInvisible()

        # Filled + synced = not visible
        collection.finishSync()
        expectInvisible()

        # Empty the list
        collection.reset()

        # Empty + unsynced = not visible
        collection.unsync()
        expectInvisible()

        # Empty + syncing = not visible
        collection.beginSync()
        expectInvisible()

        # Empty + synced = visible
        collection.finishSync()
        expectVisible()

        # Cross-check
        # Filled + synced = not visible
        addOne()
        expectInvisible()

      it 'should show the fallback after filtering all items', ->
        collection.beginSync()
        collection.finishSync()

        filterer = -> false
        collectionView.dispose()
        collectionView = new TemplatedCollectionView {collection, filterer}

        expect(collectionView.filterer).to.equal filterer
        expect(collectionView.visibleItems).to.be.empty

        fallback = collectionView.find collectionView.fallbackSelector

        if $
          [{style}] = fallback
          expect(style.display).to.equal 'block'
        else
          {style} = fallback
          expect(style.display).to.equal ''

    describe 'Loading indicator', ->

      it 'should set the loading indicator properly', ->
        if $
          {$loading} = collectionView
          expect($loading).to.be.an.instanceof $
          expect($loading).to.have.lengthOf 1

          $loading2 = collectionView.find collectionView.loadingSelector
          expect($loading[0]).to.equal $loading2[0]
        else
          {loading} = collectionView
          expect(loading).to.be.an.instanceof HTMLElement
          loading2 = collectionView.find collectionView.loadingSelector
          expect(loading).to.equal loading2

      it 'should show the loading indicator properly', ->
        loading = if $
          collectionView.$loading[0]
        else
          collectionView.loading

        expectVisible = ->
          expect(loading.style.display).to.equal if $ then 'block' else ''

        expectInvisible = ->
          expect(loading.style.display).to.equal 'none'

        # Filled + unsynced = not visible
        collection.unsync()
        expectInvisible()

        # Filled + syncing = not visible
        collection.beginSync()
        expectInvisible()

        # Filled + synced = not visible
        collection.finishSync()
        expectInvisible()

        # Empty the list
        collection.reset()

        # Empty + unsynced = not visible
        collection.unsync()
        expectInvisible()

        # Empty + syncing = visible
        collection.beginSync()
        expectVisible()

        # Empty + synced = not visible
        collection.finishSync()
        expectInvisible()

        # Cross-check
        # Filled + synced = not visible
        addOne()
        expectInvisible()

    describe 'Invalid behavior', ->
      it 'should throw an error of there is no initItemView', ->
        createCollection()
        expect(->
          collectionView = new CollectionView {collection}
        ).to.throw Error

    describe 'Disposal', ->

      it 'should also dispose when templated', ->
        collectionView.dispose()

        for key in ['$list', '$fallback', '$loading']
          expect(collectionView).not.to.have.ownProperty key

  # End TemplatedCollectionView spec
