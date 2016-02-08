'use strict'

Backbone = require 'backbone'

sinon = require 'sinon'
chai = require 'chai'
chai.use require 'sinon-chai'
chai.should()

{expect} = chai
{EventBroker, mediator, Collection, Model} = require '../src/chaplin'

describe 'Collection', ->
  collection = null

  beforeEach ->
    collection = new Collection()

  afterEach ->
    collection.dispose()

  it 'should mixin a EventBroker', ->
    prototype = Collection.prototype
    expect(prototype).to.contain.all.keys EventBroker

  it 'should serialize the models', ->
    model1 = new Model id: 1, foo: 'foo'
    model2 = new Backbone.Model id: 2, bar: 'bar'
    collection = new Collection [model1, model2]

    expect(collection.serialize).to.be.a 'function'
    expect(collection.serialize collection).to.deep.equal [
      {id: 1, foo: 'foo'}
      {id: 2, bar: 'bar'}
    ]

  describe 'Disposal', ->
    it 'should dispose itself correctly', ->
      expect(collection.disposed).to.be.false
      expect(collection.dispose).to.be.a 'function'
      collection.dispose()

      expect(collection.length).to.equal 0
      expect(collection.disposed).to.be.true
      expect(collection).to.be.frozen

    it 'should fire a dispose event', ->
      disposeSpy = sinon.spy()
      collection.on 'dispose', disposeSpy
      collection.dispose()

      disposeSpy.should.have.been.calledOnce

    it 'should unsubscribe from Pub/Sub events', ->
      pubSubSpy = sinon.spy()
      collection.subscribeEvent 'foo', pubSubSpy
      collection.dispose()

      mediator.publish 'foo'
      pubSubSpy.should.not.have.been.called

    it 'should remove all event handlers from itself', ->
      collectionBindSpy = sinon.spy()
      collection.on 'foo', collectionBindSpy
      collection.dispose()

      collection.trigger 'foo'
      collectionBindSpy.should.not.have.been.called

    it 'should unsubscribe from other events', ->
      spy = sinon.spy()
      model = new Model()

      collection.listenTo model, 'foo', spy
      collection.dispose()

      model.trigger 'foo'
      spy.should.not.have.been.called

    it 'should remove instance properties', ->
      collection.dispose()

      for key in ['model', 'models', '_byId', '_byCid']
        expect(collection).not.to.have.ownProperty key
