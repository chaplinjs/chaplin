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

    # Helpers
    # -------

    # Shortcuts for composer commands.
    reuse = ->
      mediator.execute 'composer:reuse', arguments...
    share = ->
      mediator.execute 'composer:share', arguments...
    receive = ->
      mediator.execute 'composer:receive', arguments...

    dispatch = ->
      mediator.publish 'dispatcher:dispatch'

    keys = Object.keys or _.keys

    expectCompositions = (length) ->
      expect(keys(composer.compositions).length).to.be length

    # Setup
    # -----

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

        expectCompositions 2

      it 'should recreate a composition with the same name', ->
        # Controller 1
        object1 = reuse 'view1', TestView1
        expect(object1).to.be.a TestView1
        dispatch()

        # Controller 2
        # The different constructor should be ignored, only the name matters.
        object2 = reuse 'view1', TestView2
        expect(object1).to.be object2
        dispatch()

        expectCompositions 1

      it 'should not recreate an existing composition', ->
        SpyTestView1 = sinon.spy TestView1
        SpyTestView2 = sinon.spy TestView2

        # Controller 1
        reuse 'view1', SpyTestView1
        expectCompositions 1
        dispatch()

        # Controller 2
        reuse 'view1', SpyTestView1
        reuse 'view2', SpyTestView2
        expectCompositions 2
        dispatch()

        # Controller 3
        reuse 'view1', SpyTestView1
        reuse 'view2', SpyTestView2
        reuse 'view1', SpyTestView1
        expectCompositions 2
        dispatch()

        expect(SpyTestView1).was.calledOnce()
        expect(SpyTestView2).was.calledOnce()

      it 'should check the options', ->
        options1 = id: 1
        options2 = id: 2
        SpyModel = sinon.spy Model

        # Controller 1
        reuse 'myComposition', SpyModel, options1
        dispatch()

        # Controller 2
        reuse 'myComposition', SpyModel, options1
        dispatch()

        expectCompositions 1
        expect(SpyModel).was.calledOnce()
        expect(SpyModel).was.calledWith options1
        expect(composer.compositions.myComposition.options).to.eql options1

        # Controller 3
        reuse 'myComposition', SpyModel, options2
        dispatch()

        expectCompositions 1
        expect(SpyModel).was.calledTwice()
        expect(SpyModel).was.calledWith options2
        expect(composer.compositions.myComposition.options).to.eql options2

      it 'should dispose stale compositions', ->
        # Controller 1
        reuse 'view1', TestView1
        dispatch()
        expectCompositions 1
        expect(composer.compositions.view1.stale()).to.be true

        # Controller 2
        reuse 'view2', TestView2
        dispatch()

        expectCompositions 1
        expect(composer.compositions.view2).to.be.a Composition
        expect(composer.compositions.view2.object).to.be.a TestView2
        expect(composer.compositions.view2.stale()).to.be true

        # Controller 3
        # No reuse
        dispatch()
        expectCompositions 0

    describe 'reuse: custom create and check', ->

      it 'should create a new composition', ->
        # Controller 1
        create = sinon.spy ->
          @view = new TestView1()
        object = reuse 'myComposition', { create }
        expect(create).was.called()
        expect(object).to.be.a Composition
        expectCompositions 1
        expect(composer.compositions.myComposition.view).to.be.a TestView1
        dispatch()

      it 'should dispose stale compositions', ->
        # Controller 1
        create = sinon.spy ->
          @view1 = new TestView1()
          @view2 = new TestView2()
        check = sinon.spy -> false
        object = reuse 'myComposition', { create, check }
        expect(create).was.called()
        expect(check).was.notCalled()
        expect(object).to.be.a Composition
        expectCompositions 1
        expect(composer.compositions.myComposition.view1).to.be.a TestView1
        expect(composer.compositions.myComposition.view2).to.be.a TestView2
        dispatch()
        expectCompositions 1
        expect(composer.compositions.myComposition.stale()).to.be true

        # Controller 2
        create = sinon.spy ->
          @view3 = new TestView2()
        object = reuse 'myComposition', { create, check }
        expect(create).was.called()
        expect(check).was.called()
        expect(object).to.be.a Composition
        expectCompositions 1
        expect(composer.compositions.myComposition.view3).to.be.a TestView2
        dispatch()

        # Controller 3
        # No reuse
        dispatch()
        expectCompositions 0

    describe 'reuse: custom composition', ->

      it 'should create custom compositions', ->
        create = sinon.spy ->
          @model = new Model()

        class CustomComposition extends Composition
          create: create

        reuse 'myComposition', CustomComposition
        dispatch()

        expect(create).was.called()
        expect(composer.compositions.myComposition).to.be.a CustomComposition
        expect(composer.compositions.myComposition.model).to.be.a Model

      it 'should check the options', ->
        options1 = id: 1
        options2 = id: 2

        # Controller 1
        create = sinon.spy (options) ->
          @model = new Model options
        check = sinon.spy (options) ->
          @options.id is options.id

        class CustomComposition extends Composition
          create: create
          check: check

        reuse 'myComposition', CustomComposition, options1
        expect(create).was.calledWith options1
        expect(check).was.notCalled()
        expect(composer.compositions.myComposition.options).to.eql options1
        dispatch()

        # Controller 2
        reuse 'myComposition', CustomComposition, options1
        expect(create).was.calledOnce()
        expect(check).was.calledWith options1
        dispatch()

        # Controller 3
        reuse 'myComposition', CustomComposition, options2
        expect(create).was.calledTwice()
        expect(check).was.calledTwice()
        expect(check).was.calledWith options2
        expect(composer.compositions.myComposition.options).to.eql options2
        dispatch()

    describe 'share', ->

      it 'should allow to share objects', ->
        model = new Model id: 123
        view = new TestView1 model: model
        share

    describe 'receive', ->

      it 'should allow a composition to be received', ->
        reuse 'myComposition', Model, id: 123
        object = receive 'myComposition'
        expect(object).to.be.a Model
        expect(object.id).to.be 123
        expect(composer.compositions.myComposition.object).to.be object
        dispatch()

      it 'should check the options', ->
        options1 = id: 1
        options2 = id: 2

        reuse 'myComposition', Model, options1

        object = receive 'myComposition', options1
        expect(object).to.be.a Model

        object = receive 'myComposition', options2
        expect(object).to.be undefined

    describe 'Error handling', ->

      it 'should throw an error for invalid invocations', ->
        expect(->
          reuse()
        ).to.throwError()

        expect(->
          reuse {}
        ).to.throwError()

        expect(->
          reuse 'myComposition', null
        ).to.throwError()

        expect(->
          reuse 'myComposition', {}
        ).to.throwError()

        expect(->
          reuse create: /a/, check: ''
        ).to.throwError()

    describe 'Disposal', ->

      it 'should dispose itself correctly', ->
        expect(composer.dispose).to.be.a 'function'
        composer.dispose()

        expect(composer).not.to.have.own.property 'compositions'

        expect(composer.disposed).to.be true
        expect(Object.isFrozen(composer)).to.be true if Object.isFrozen

    describe 'Extendability', ->

      it 'should be extendable', ->
        expect(Composer.extend).to.be.a 'function'

        DerivedComposer = Composer.extend()
        derivedComposer = new DerivedComposer()
        expect(derivedComposer).to.be.a Composer

        derivedComposer.dispose()
