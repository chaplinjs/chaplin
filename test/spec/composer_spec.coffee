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

    composer = null
    dispatcher = null

    class TestModel extends Model

    class NullView extends View
      getTemplateFunction: -> # Do nothing

    class TestView1 extends NullView
    class TestView2 extends NullView
    class TestView3 extends NullView
    class TestView4 extends NullView

    keys = Object.keys or _.keys

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
      mediator.execute 'composer:compose', 'test1', TestView1
      expect(keys(composer.compositions).length).to.be 1
      expect(composer.compositions['test1'].item).to.be.a TestView1
      mediator.publish 'dispatcher:dispatch'

      mediator.execute 'composer:compose', 'test1', TestView1
      mediator.execute 'composer:compose', 'test2', TestView2
      expect(keys(composer.compositions).length).to.be 2
      expect(composer.compositions['test2'].item).to.be.a TestView2
      mediator.publish 'dispatcher:dispatch'

    it 'should not initialize a view if it is already composed', ->
      mediator.execute 'composer:compose', 'test1', TestView1
      expect(keys(composer.compositions).length).to.be 1
      mediator.publish 'dispatcher:dispatch'

      mediator.execute 'composer:compose', 'test1', TestView1
      mediator.execute 'composer:compose', 'test2', TestView2
      expect(keys(composer.compositions).length).to.be 2
      mediator.publish 'dispatcher:dispatch'

      mediator.execute 'composer:compose', 'test1', TestView1
      mediator.execute 'composer:compose', 'test2', TestView2
      mediator.execute 'composer:compose', 'test1', TestView1
      expect(keys(composer.compositions).length).to.be 2
      mediator.publish 'dispatcher:dispatch'

    it 'should dispose a compose view if it is not re-composed', ->
      mediator.execute 'composer:compose', 'test1', TestView1
      expect(keys(composer.compositions).length).to.be 1

      mediator.publish 'dispatcher:dispatch'
      mediator.execute 'composer:compose', 'test2', TestView2
      mediator.publish 'dispatcher:dispatch'

      expect(keys(composer.compositions).length).to.be 1
      expect(composer.compositions['test2'].item).to.be.a TestView2

    # composing with the long form
    # -----------------------------

    it 'should invoke compose when a view should be composed', ->
      mediator.execute 'composer:compose', 'weird',
        compose: -> @view = new TestView1()
        check: -> false

      expect(keys(composer.compositions).length).to.be 1
      expect(composer.compositions['weird'].view).to.be.a TestView1

      mediator.publish 'dispatcher:dispatch'
      expect(keys(composer.compositions).length).to.be 1

      mediator.execute 'composer:compose', 'weird',
        compose: -> @view = new TestView2()

      mediator.publish 'dispatcher:dispatch'
      expect(keys(composer.compositions).length).to.be 1
      expect(composer.compositions['weird'].view).to.be.a TestView2

    it 'should dispose the entire composition when necessary', ->
      spy = sinon.spy()

      mediator.execute 'composer:compose', 'weird',
        compose: ->
          @dagger = new TestView1()
          @dagger2 = new TestView1()
        check: -> false

      expect(keys(composer.compositions).length).to.be 1
      expect(composer.compositions['weird'].dagger).to.be.a TestView1

      mediator.publish 'dispatcher:dispatch'
      expect(keys(composer.compositions).length).to.be 1

      mediator.execute 'composer:compose', 'weird',
        compose: -> @frozen = new TestView2()
        check: -> false

      mediator.publish 'dispatcher:dispatch'
      expect(keys(composer.compositions).length).to.be 1
      expect(composer.compositions['weird'].frozen).to.be.a TestView2

      mediator.publish 'dispatcher:dispatch'
      expect(keys(composer.compositions).length).to.be 0

    # various compose forms
    # ---------------------
    it 'should allow a function to be composed', ->
      spy = sinon.spy()

      mediator.execute 'composer:compose', 'spy', spy
      mediator.publish 'dispatcher:dispatch'

      expect(spy).was.called()

    it 'should allow a function to be composed with options', ->
      spy = sinon.spy()
      params = {foo: 123, bar: 123}

      mediator.execute 'composer:compose', 'spy', params, spy
      mediator.publish 'dispatcher:dispatch'

      expect(spy).was.calledWith(params)

    it 'should allow a options hash with a function to be composed with options', ->
      spy = sinon.spy()
      params = {foo: 123, bar: 123}

      mediator.execute 'composer:compose', 'spy',
        options: params
        compose: spy

      mediator.publish 'dispatcher:dispatch'

      expect(spy).was.calledWith(params)

    it 'should allow a model to be composed', ->
      mediator.execute 'composer:compose', 'spy', Model

      expect(composer.compositions['spy'].item).to.be.a Model

      mediator.publish 'dispatcher:dispatch'

    it 'should allow a composition to be composed', ->
      spy = sinon.spy()

      class CustomComposition extends Composition
        compose: spy

      mediator.execute 'composer:compose', 'spy', CustomComposition
      mediator.publish 'dispatcher:dispatch'

      expect(composer.compositions['spy'].item).to.be.a Composition
      expect(composer.compositions['spy'].item).to.be.a CustomComposition

      expect(spy).was.called()

    it 'should allow a composition to be composed with options', ->
      spy = sinon.spy()
      params = {foo: 123, bar: 123}

      class CustomComposition extends Composition
        compose: spy

      mediator.execute 'composer:compose', 'spy', CustomComposition, params
      mediator.publish 'dispatcher:dispatch'

      expect(composer.compositions['spy'].item).to.be.a Composition
      expect(composer.compositions['spy'].item).to.be.a CustomComposition

      expect(spy).was.called()
      expect(spy).was.calledWith(params)

    it 'should allow a composition to be retreived', ->
      mediator.execute 'composer:compose', 'spy', Model
      item = mediator.execute 'composer:retrieve', 'spy'
      expect(item).to.be composer.compositions['spy'].item
      mediator.publish 'dispatcher:dispatch'

    it 'should throw for invalid invocations', ->
      expect(->
        mediator.execute 'composer:compose', 'spy', null
      ).to.throwError()
      expect(->
        mediator.execute 'composer:compose', compose: /a/, check: ''
      ).to.throwError()

    # disposal
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
