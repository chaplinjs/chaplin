define [
  'underscore'
  'chaplin/mediator'
  'chaplin/lib/event_broker'
  'chaplin/lib/composition'
  'chaplin/composer'
  'chaplin/controllers/controller'
  'chaplin/views/view'
  'chaplin/models/model'
], (_, mediator, EventBroker, Composition, Composer, Controller, View, Model) ->
  'use strict'

  describe 'Composer', ->
    #console.debug 'Composer spec'

    # Initialize shared variables
    composer = null
    dispatcher = null

    # Test classes
    # ------------

    class NullView extends View
      getTemplateFunction: -> # Do nothing
    class TestView1 extends NullView
    class TestView2 extends NullView
    class TestModel extends Model

    # Helpers
    # -------

    # Shortcuts for composer commands.
    reuse = ->
      mediator.execute 'composer:reuse', arguments...
    share = ->
      mediator.execute 'composer:share', arguments...
    retrieve = ->
      mediator.execute 'composer:retrieve', arguments...

    dispatch = ->
      mediator.publish 'dispatcher:dispatch'

    keys = Object.keys or _.keys

    expectCompositions = (length) ->
      expect(keys(composer.compositions).length).to.be length

    # Setup

    beforeEach ->
      # Instantiate
      composer = new Composer()

    afterEach ->
      # Dispose
      composer.dispose()
      composer = null

    describe 'mixin', ->

      it 'should mixin a EventBroker', ->
        for own name of EventBroker
          expect(composer[name]).to.be EventBroker[name]

    describe 'initialize', ->

      it 'should initialize', ->
        expect(composer.initialize).to.be.a 'function'
        composer.initialize()
        expect(composer.compositions).to.eql {}

    describe 'reuse: short form', ->

      it 'should create a new composition', ->
        # Controller 1
        object = reuse 'view1', TestView1
        expect(object).to.be.a TestView1
        expectCompositions 1
        expect(composer.compositions.view1).to.be.a Composition
        expect(composer.compositions.view1.object).to.be.a TestView1
        dispatch()

        # Controller 2
        object1 = reuse 'view1', TestView1
        object2 = reuse 'view2', TestView2
        expect(object1).to.be.a TestView1
        expect(object2).to.be.a TestView2
        expectCompositions 2
        expect(composer.compositions.view2).to.be.a Composition
        expect(composer.compositions.view2.object).to.be.a TestView2
        dispatch()

      it 'should recreate a composition', ->
        # Controller 1
        object = reuse 'view1', TestView1
        expect(object).to.be.a TestView1
        dispatch()

        # Controller 2
        reuse 'view1', TestView2
        expect(object).to.be.a TestView2
        dispatch()

        expectCompositions 1

      it 'should not recreate an existing composition', ->
        # Controller 1
        reuse 'view1', TestView1
        expectCompositions 1
        dispatch()

        # Controller 2
        reuse 'view1', TestView1
        reuse 'view2', TestView2
        expectCompositions 2
        dispatch()

        # Controller 3
        reuse 'view1', TestView1
        reuse 'view2', TestView2
        reuse 'view1', TestView1
        expectCompositions 2
        dispatch()

      it 'should dispose stale compositions', ->
        # Controller 1
        reuse 'view1', TestView1
        expectCompositions 1

        # Controller 2
        dispatch()

        # Controller 3
        reuse 'view2', TestView2
        dispatch()

        expectCompositions 1
        expect(composer.compositions.view2).to.be.a Composition
        expect(composer.compositions.view2.object).to.be.a TestView2

    describe 'reuse: custom create and check', ->

      it 'should create a new composition', ->
        # Controller 1
        create = sinon.spy ->
          @view = new TestView1()
        object = reuse 'myComposition', { create }
        expect(object).to.be.a Composition
        expect(create).was.called()
        expect(object1).to.be.a TestView2
        expectCompositions 1
        expect(composer.compositions.myComposition.view).to.be.a TestView1
        dispatch()
        expectCompositions 1

      it 'should recreate a new composition with a different create', ->
        # Controller 1
        create = sinon.spy ->
          @view = new TestView1()
        reuse 'myComposition', { create }

        # Controller 2
        create = sinon.spy ->
          @view = new TestView1()
        reuse 'myComposition', { create }
          create: ->
            @view = new TestView2()
        dispatch()

        expectCompositions 1
        expect(composer.compositions.myComposition.view).to.be.a TestView2

      it 'should dispose stale compositions', ->
        # Controller 1
        create = sinon.spy ->
          @view1 = new TestView()
          @view2 = new TestView1()
        check = sinon.spy -> false
        reuse 'myComposition', { create }
        expect(create).was.called()
        expect(check).was.notCalled()
        expectCompositions 1
        expect(composer.compositions.myComposition.view1).to.be.a TestView1
        expect(composer.compositions.myComposition.view2).to.be.a TestView2

        dispatch()
        expectCompositions 1

        # Controller 2
        create = sinon.spy ->
          @view3 = new TestView2()
        check = sinon.spy -> false
        reuse 'myComposition', { create, check }
        expect(create).was.called()
        expect(check).was.called()
        dispatch()
        expectCompositions 1
        expect(composer.compositions.myComposition.view3).to.be.a TestView2

        # Controller 3
        dispatch()
        expectCompositions 0

    describe 'reuse: custom composition', ->

      it 'should create custom compositions', ->
        create = sinon.spy ->
          @model = new TestModel()

        class CustomComposition extends Composition
          create: create

        reuse 'myComposition', CustomComposition
        dispatch()

        expect(create).was.called()
        expect(composer.compositions.myComposition).to.be.a CustomComposition
        expect(composer.compositions.myComposition.model).to.be.a TestModel

      it 'should create a custom composition with options', ->
        options1 = {id: 1, foo: 123}
        options2 = {id: 1, foo: 456}

        # Controller 1
        create = sinon.spy ->
          @model = new TestModel()
        check = sinon.spy (options) ->
          @options.id is options.id

        class CustomComposition extends Composition
          create: create
          check: check

        reuse 'myComposition', CustomComposition, options1
        expect(create).was.calledWith(params)
        expect(check).was.notCalled()
        dispatch()

        expect(composer.compositions.myComposition.options).to.be options

        # Controller
        reuse 'myComposition', CustomComposition, options2
        dispatch()



    describe 'share', ->


    describe 'retrieve', ->

    # composing with the short form
    # -----------------------------

    # composing with the long form
    # -----------------------------


    # various reuse forms
    # ---------------------



    it 'should allow a composition to be retreived', ->
      reuse 'myComposition', Model
      object = retrieve 'myComposition'
      expect(object).to.be composer.compositions.myComposition.object
      dispatch()

    it 'should throw an error for invalid invocations', ->
      expect(->
        reuse 'myComposition', null
      ).to.throwError()
      expect(->
        reuse compose: /a/, check: ''
      ).to.throwError()

    # Disposal
    # --------

    it 'should dispose itself correctly', ->
      expect(composer.dispose).to.be.a 'function'
      composer.dispose()

      for prop in ['compositions']
        expect(composer.hasOwnProperty prop).to.not.be.ok()

      expect(composer.disposed).to.be true
      expect(Object.isFrozen(composer)).to.be true if Object.isFrozen

    # extensible
    # ----------

    it 'should be extendable', ->
      expect(Composer.extend).to.be.a 'function'

      DerivedComposer = Composer.extend()
      derivedComposer = new DerivedComposer()
      expect(derivedComposer).to.be.a Composer

      derivedComposer.dispose()
