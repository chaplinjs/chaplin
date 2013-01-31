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

    class NullView extends View
      getTemplateFunction: -> # Do nothing

    class TestView1 extends NullView
    class TestView2 extends NullView
    class TestView3 extends NullView
    class TestView4 extends NullView

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
      expect(composer.compositions).to.eql {}

    # composing with the short form
    # -----------------------------

    it 'should initialize a view when it is composed for the first time', ->
      mediator.publish '!composer:compose', 'test1', TestView1
      expect(_(composer.compositions).keys().length).to.be 1
      expect(composer.compositions['test1'].view).to.be.a TestView1
      mediator.publish 'startupController'

      mediator.publish '!composer:compose', 'test1', TestView1
      mediator.publish '!composer:compose', 'test2', TestView2
      expect(_(composer.compositions).keys().length).to.be 2
      expect(composer.compositions['test2'].view).to.be.a TestView2
      mediator.publish 'startupController'

    it 'should not initialize a view if it is already composed', ->
      mediator.publish '!composer:compose', 'test1', TestView1
      expect(_(composer.compositions).keys().length).to.be 1
      mediator.publish 'startupController'

      mediator.publish '!composer:compose', 'test1', TestView1
      mediator.publish '!composer:compose', 'test2', TestView2
      expect(_(composer.compositions).keys().length).to.be 2
      mediator.publish 'startupController'

      mediator.publish '!composer:compose', 'test1', TestView1
      mediator.publish '!composer:compose', 'test2', TestView2
      mediator.publish '!composer:compose', 'test1', TestView1
      expect(_(composer.compositions).keys().length).to.be 2
      mediator.publish 'startupController'

    it 'should dispose a compose view if it is not re-composed', ->
      mediator.publish '!composer:compose', 'test1', TestView1
      expect(_(composer.compositions).keys().length).to.be 1

      toBeDisposed = composer.compositions['test1'].view
      mediator.publish 'startupController'

      mediator.publish '!composer:compose', 'test2', TestView2

      toBeDisposed = composer.compositions['test2'].view
      mediator.publish 'startupController'

      expect(_(composer.compositions).keys().length).to.be 1
      expect(composer.compositions['test2'].view).to.be.a TestView2

    # composing with the long form
    # -----------------------------

    it 'should invoke compose when a view should be composed', ->
      mediator.publish '!composer:compose', 'weird',
        compose: ->
          type: TestView1
          view: new TestView1()
        check: -> false

      expect(_(composer.compositions).keys().length).to.be 1
      expect(composer.compositions['weird'].view).to.be.a TestView1

      mediator.publish 'startupController'
      expect(_(composer.compositions).keys().length).to.be 1

      mediator.publish '!composer:compose', 'weird',
        compose: ->
          type: TestView2
          view: new TestView2()
        check: -> @type is TestView2

      mediator.publish 'startupController'
      expect(_(composer.compositions).keys().length).to.be 1
      expect(composer.compositions['weird'].view).to.be.a TestView2

    it 'should dispose the entire composition when necessary', ->
      view1 = null
      view12 = null
      view2 = null
      spy = sinon.spy()

      mediator.publish '!composer:compose', 'weird',
        compose: ->
          dagger: view1 = new TestView1()
          dagger2: view12 = new TestView1()
        check: -> false

      expect(_(composer.compositions).keys().length).to.be 1
      expect(composer.compositions['weird'].dagger).to.be.a TestView1

      mediator.publish 'startupController'
      expect(_(composer.compositions).keys().length).to.be 1

      mediator.publish '!composer:compose', 'weird',
        compose: -> frozen: view2 = new TestView2()
        check: -> false

      mediator.publish 'startupController'
      expect(_(composer.compositions).keys().length).to.be 1
      expect(composer.compositions['weird'].frozen).to.be.a TestView2

      mediator.publish 'startupController'
      expect(_(composer.compositions).keys().length).to.be 0

    # disposal
    # --------

    it 'should dispose itself correctly', ->
      expect(composer.dispose).to.be.a 'function'
      composer.dispose()

      for prop in ['compositions']
        expect(_(composer).has prop).to.not.be.ok()

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
