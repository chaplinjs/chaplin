'use strict'
Backbone = require 'backbone'
sinon = require 'sinon'
{EventBroker, mediator, Collection, Model} = require '../build/chaplin'

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

    expect(collection).to.respondTo 'serialize'
    expect(collection.serialize collection).to.deep.equal [
      {id: 1, foo: 'foo'}
      {id: 2, bar: 'bar'}
    ]

  describe 'Disposal', ->
    it 'should dispose itself correctly', ->
      expect(collection.disposed).to.be.false
      expect(collection).to.respondTo 'dispose'
      collection.dispose()

      expect(collection).to.be.empty
      expect(collection.disposed).to.be.true
      expect(collection).to.be.frozen

    it 'should fire a dispose event', ->
      disposeSpy = sinon.spy()
      collection.on 'dispose', disposeSpy
      collection.dispose()

      expect(disposeSpy).to.have.been.calledOnce

    it 'should unsubscribe from Pub/Sub events', ->
      pubSubSpy = sinon.spy()
      collection.subscribeEvent 'foo', pubSubSpy
      collection.dispose()

      mediator.publish 'foo'
      expect(pubSubSpy).to.not.have.been.called

    it 'should remove all event handlers from itself', ->
      collectionBindSpy = sinon.spy()
      collection.on 'foo', collectionBindSpy
      collection.dispose()

      collection.trigger 'foo'
      expect(collectionBindSpy).to.not.have.been.called

    it 'should unsubscribe from other events', ->
      spy = sinon.spy()
      model = new Model()

      collection.listenTo model, 'foo', spy
      collection.dispose()

      model.trigger 'foo'
      expect(spy).to.not.have.been.called

    it 'should remove instance properties', ->
      collection.dispose()

      for key in ['model', 'models', '_byCid']
        expect(collection).not.to.have.ownProperty key

      expect(collection._byId).to.deep.equal {}
