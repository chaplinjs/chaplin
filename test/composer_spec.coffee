'use strict'
sinon = require 'sinon'
{Composer, Controller, Dispatcher, Composition} = require '../build/chaplin'
{EventBroker, Router, mediator, Model, View} = require '../build/chaplin'

describe 'Composer', ->
  composer = null

  class TestModel extends Model

  class NullView extends View
    getTemplateFunction: -> # Do nothing

  class TestView1 extends NullView
  class TestView2 extends NullView
  class TestView3 extends NullView
  class TestView4 extends NullView

  beforeEach ->
    # Instantiate
    composer = new Composer()

  afterEach ->
    # Dispose
    composer.dispose()
    composer = null

  # mixin
  # -----

  it 'should mixin a EventBroker', ->
    prototype = Composer.prototype
    expect(prototype).to.contain.all.keys EventBroker

  # initialize
  # ----------

  it 'should initialize', ->
    expect(composer).to.respondTo 'initialize'
    composer.initialize()
    expect(composer.compositions).to.deep.equal {}

  # composing with the short form
  # -----------------------------

  it 'should initialize a view when it is composed for the first time', ->
    mediator.execute 'composer:compose', 'test1', TestView1
    expect(Object.keys composer.compositions).to.have.lengthOf 1
    expect(composer.compositions['test1'].item).to.be.an.instanceof TestView1
    mediator.publish 'dispatcher:dispatch'

    mediator.execute 'composer:compose', 'test1', TestView1
    mediator.execute 'composer:compose', 'test2', TestView2
    expect(Object.keys composer.compositions).to.have.lengthOf 2
    expect(composer.compositions['test2'].item).to.be.an.instanceof TestView2
    mediator.publish 'dispatcher:dispatch'

  it 'should not initialize a view if it is already composed', ->
    mediator.execute 'composer:compose', 'test1', TestView1
    expect(Object.keys composer.compositions).to.have.lengthOf 1
    mediator.publish 'dispatcher:dispatch'

    mediator.execute 'composer:compose', 'test1', TestView1
    mediator.execute 'composer:compose', 'test2', TestView2
    expect(Object.keys composer.compositions).to.have.lengthOf 2
    mediator.publish 'dispatcher:dispatch'

    mediator.execute 'composer:compose', 'test1', TestView1
    mediator.execute 'composer:compose', 'test2', TestView2
    mediator.execute 'composer:compose', 'test1', TestView1
    expect(Object.keys composer.compositions).to.have.lengthOf 2
    mediator.publish 'dispatcher:dispatch'

  it 'should dispose a compose view if it is not re-composed', ->
    mediator.execute 'composer:compose', 'test1', TestView1
    expect(Object.keys composer.compositions).to.have.lengthOf 1

    mediator.publish 'dispatcher:dispatch'
    mediator.execute 'composer:compose', 'test2', TestView2
    mediator.publish 'dispatcher:dispatch'

    expect(Object.keys composer.compositions).to.have.lengthOf 1
    expect(composer.compositions['test2'].item).to.be.an.instanceof TestView2

  # composing with the long form
  # -----------------------------

  it 'should invoke compose when a view should be composed', ->
    mediator.execute 'composer:compose', 'weird',
      compose: -> @view = new TestView1()
      check: -> false

    expect(Object.keys composer.compositions).to.have.lengthOf 1
    expect(composer.compositions['weird'].view).to.be.an.instanceof TestView1

    mediator.publish 'dispatcher:dispatch'
    expect(Object.keys composer.compositions).to.have.lengthOf 1

    mediator.execute 'composer:compose', 'weird',
      compose: -> @view = new TestView2()

    mediator.publish 'dispatcher:dispatch'
    expect(Object.keys composer.compositions).to.have.lengthOf 1
    expect(composer.compositions['weird'].view).to.be.an.instanceof TestView2

  it 'should dispose the entire composition when necessary', ->
    spy = sinon.spy()

    mediator.execute 'composer:compose', 'weird',
      compose: ->
        @dagger = new TestView1()
        @dagger2 = new TestView1()
      check: -> false

    expect(Object.keys composer.compositions).to.have.lengthOf 1
    expect(composer.compositions['weird'].dagger).to.be.an.instanceof TestView1

    mediator.publish 'dispatcher:dispatch'
    expect(Object.keys composer.compositions).to.have.lengthOf 1

    mediator.execute 'composer:compose', 'weird',
      compose: -> @frozen = new TestView2()
      check: -> false

    mediator.publish 'dispatcher:dispatch'
    expect(Object.keys composer.compositions).to.have.lengthOf 1
    expect(composer.compositions['weird'].frozen).to.be.an.instanceof TestView2

    mediator.publish 'dispatcher:dispatch'
    expect(Object.keys composer.compositions).to.be.empty

  # various compose forms
  # ---------------------
  it 'should allow a function to be composed', ->
    spy = sinon.spy()

    mediator.execute 'composer:compose', 'spy', spy
    mediator.publish 'dispatcher:dispatch'

    expect(spy).to.have.been.calledOnce

  it 'should allow a function to be composed with options', ->
    spy = sinon.spy()
    params = {foo: 123, bar: 123}

    mediator.execute 'composer:compose', 'spy', params, spy
    mediator.publish 'dispatcher:dispatch'

    expect(spy).to.have.been.calledWith params

  it 'should allow options hash with function to be composed with options', ->
    spy = sinon.spy()
    params = {foo: 123, bar: 123}

    mediator.execute 'composer:compose', 'spy',
      options: params
      compose: spy

    mediator.publish 'dispatcher:dispatch'

    expect(spy).to.have.been.calledWith params

  it 'should allow a model to be composed', ->
    mediator.execute 'composer:compose', 'spy', Model
    expect(composer.compositions['spy'].item).to.be.an.instanceof Model

    mediator.publish 'dispatcher:dispatch'

  it 'should allow a model to be composed with options', ->
    mediator.execute 'composer:compose', 'spy', Model, { collection: 2 }
    expect(composer.compositions['spy'].item.collection).to.equal 2

    mediator.publish 'dispatcher:dispatch'

  it 'should allow a composition to be composed', ->
    spy = sinon.spy()

    class CustomComposition extends Composition
      compose: spy

    mediator.execute 'composer:compose', 'spy', CustomComposition
    mediator.publish 'dispatcher:dispatch'

    item = composer.compositions['spy'].item

    expect(item).to.be.an.instanceof Composition
    expect(item).to.be.an.instanceof CustomComposition

    expect(spy).to.have.been.calledOnce

  it 'should allow a composition to be composed with options', ->
    spy = sinon.spy()
    params = {foo: 123, bar: 123}

    class CustomComposition extends Composition
      compose: spy

    mediator.execute 'composer:compose', 'spy', CustomComposition, params
    mediator.publish 'dispatcher:dispatch'

    item = composer.compositions['spy'].item
    expect(item).to.be.an.instanceof Composition
    expect(item).to.be.an.instanceof CustomComposition

    expect(spy).to.have.been.calledOnce
    expect(spy).to.have.been.calledWith params

  it 'should allow a composition to be retreived', ->
    mediator.execute 'composer:compose', 'spy', Model
    item = mediator.execute 'composer:retrieve', 'spy'
    expect(item).to.equal composer.compositions['spy'].item
    mediator.publish 'dispatcher:dispatch'

  it 'should throw for invalid invocations', ->
    expect(->
      mediator.execute 'composer:compose', 'spy', null
    ).to.throw Error

    expect(->
      mediator.execute 'composer:compose', compose: /a/, check: ''
    ).to.throw Error

  # disposal
  # --------

  it 'should dispose itself correctly', ->
    expect(composer.disposed).to.be.false
    expect(composer).to.respondTo 'dispose'
    composer.dispose()

    expect(composer).not.to.have.ownProperty 'compositions'
    expect(composer.disposed).to.be.true
    expect(composer).to.be.frozen

  # extensible
  # ----------

  it 'should be extendable', ->
    expect(Composer).itself.to.respondTo 'extend'

    DerivedComposer = Composer.extend()
    derivedComposer = new DerivedComposer()
    expect(derivedComposer).to.be.an.instanceof Composer

    derivedComposer.dispose()
