define [
  'underscore'
  'chaplin/mediator'
  'chaplin/lib/event_broker'
  'chaplin/composer'
  'chaplin/controllers/controller'
  'chaplin/views/view'
  'chaplin/models/model'
], (_, mediator, EventBroker, Composer, Controller, View, Model) ->
  'use strict'

  describe 'Composer', ->
    #console.debug 'Composer spec'

    composer = null
    dispatcher = null

    class TestModel extends Model

    class TestView1 extends View
    class TestView2 extends View
    class TestView3 extends View
    class TestView4 extends View

    beforeEach ->
      # Instantiate
      composer = new Composer

    afterEach ->
      # Dispose
      composer.dispose()
      composer = null

    # mixin
    # -----

    it 'should mixin a EventBroker', ->
      for own name, value of EventBroker
        expect(composer[name]).to.be EventBroker[name]

    # initialize
    # ----------

    it 'should initialize', ->
      expect(composer.initialize).to.be.a 'function'
      composer.initialize()
      expect(composer.compositions).to.eql []

    # composing with the short form
    # -----------------------------

    it 'should initialize a view when it is composed for the first time', ->
      mediator.publish '!composer:compose', TestView1
      expect(composer.compositions.length).to.be 1
      expect(composer.compositions[0].view).to.be.a TestView1
      mediator.publish 'startupController'

      mediator.publish '!composer:compose', TestView1
      mediator.publish '!composer:compose', TestView2
      expect(composer.compositions.length).to.be 2
      expect(composer.compositions[1].view).to.be.a TestView2
      mediator.publish 'startupController'

    it 'should not initialize a view if it is already composed', ->
      mediator.publish '!composer:compose', TestView1
      expect(composer.compositions.length).to.be 1
      mediator.publish 'startupController'

      mediator.publish '!composer:compose', TestView1
      mediator.publish '!composer:compose', TestView2
      expect(composer.compositions.length).to.be 2
      mediator.publish 'startupController'

      mediator.publish '!composer:compose', TestView1
      mediator.publish '!composer:compose', TestView2
      mediator.publish '!composer:compose', TestView1
      expect(composer.compositions.length).to.be 2
      mediator.publish 'startupController'

    it 'should dispose a compose view if it is not re-composed', ->
      spy = sinon.spy()
      mediator.subscribe 'view:dispose', spy

      mediator.publish '!composer:compose', TestView1
      expect(composer.compositions.length).to.be 1

      toBeDisposed = composer.compositions[0].view
      mediator.publish 'startupController'
      expect(spy).was.notCalled()

      mediator.publish '!composer:compose', TestView2

      toBeDisposed = composer.compositions[0].view
      mediator.publish 'startupController'

      expect(composer.compositions.length).to.be 1
      expect(composer.compositions[0].view).to.be.a TestView2

      expect(spy).was.calledWith toBeDisposed

    # composing with the long form
    # -----------------------------

    it 'should invoke compose when a view should be composed', ->
      mediator.publish '!composer:compose',
        compose: ->
          type: TestView1
          view: new TestView1()
        check: (x) -> false

      expect(composer.compositions.length).to.be 1
      expect(composer.compositions[0].view).to.be.a TestView1

      mediator.publish 'startupController'
      expect(composer.compositions.length).to.be 1

      mediator.publish '!composer:compose',
        compose: ->
          type: TestView2
          view: new TestView2()
        check: (x) -> x.type is TestView2

      mediator.publish 'startupController'
      expect(composer.compositions.length).to.be 1
      expect(composer.compositions[0].view).to.be.a TestView2

    it 'should dispose the entire composition when necessary', ->
      view1 = null
      view12 = null
      view2 = null
      spy = sinon.spy()

      mediator.subscribe 'view:dispose', spy
      mediator.publish '!composer:compose',
        compose: ->
          dagger: view1 = new TestView1()
          dagger2: view12 = new TestView1()
        check: (x) -> false

      expect(composer.compositions.length).to.be 1
      expect(composer.compositions[0].dagger).to.be.a TestView1

      mediator.publish 'startupController'
      expect(composer.compositions.length).to.be 1

      mediator.publish '!composer:compose',
        compose: -> frozen: view2 = new TestView2()
        check: (x) -> false

      mediator.publish 'startupController'
      expect(composer.compositions.length).to.be 1
      expect(composer.compositions[0].frozen).to.be.a TestView2
      expect(spy).was.calledWith view1

      mediator.publish 'startupController'
      expect(composer.compositions.length).to.be 0
      expect(spy).was.calledWith view2

    # disposal
    # --------

    it 'should dispose itself correctly', ->
      expect(composer.dispose).to.be.a 'function'
      composer.dispose()

      for prop in ['compositions']
        expect(_(composer).has prop).to.not.be.ok()

      expect(composer.disposed).to.be true
      if Object.isFrozen
        expect(Object.isFrozen(composer)).to.be true

    # extensible
    # ----------

    it 'should be extendable', ->
      expect(Composer.extend).to.be.a 'function'

      DerivedComposer = Composer.extend()
      derivedComposer = new DerivedComposer()
      expect(derivedComposer).to.be.a Composer

      derivedComposer.dispose()
