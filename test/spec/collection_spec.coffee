define [
  'underscore'
  'backbone'
  'chaplin/mediator'
  'chaplin/models/collection'
  'chaplin/models/model'
  'chaplin/lib/event_broker'
], (_, Backbone, mediator, Collection, Model, EventBroker) ->
  'use strict'

  describe 'Collection', ->
    collection = null

    beforeEach ->
      collection = new Collection

    afterEach ->
      collection.dispose()

    expectOrder = (order) ->
      for id, index in order
        expect(collection.at(index).id).to.be id

    it 'should mixin a EventBroker', ->
      for own name, value of EventBroker
        expect(collection[name]).to.be EventBroker[name]

    it 'should initialize a Deferred', ->
      expect(collection.initDeferred).to.be.a 'function'
      collection.initDeferred()
      for method in ['done', 'fail', 'progress', 'state', 'promise']
        expect(typeof collection[method]).to.be 'function'
      expect(collection.state()).to.be 'pending'

    it 'should add models atomically', ->
      expect(collection.addAtomic).to.be.a 'function'

      collection.reset ({id: i} for i in [0..2])

      addSpy = sinon.spy()
      collection.on 'add', addSpy
      resetSpy = sinon.spy()
      collection.on 'reset', resetSpy

      collection.addAtomic ({id: i} for i in [3..5])
      expectOrder [0, 1, 2, 3, 4, 5]

      expect(addSpy).was.notCalled()
      expect(resetSpy).was.called()

    it 'should add models atomically at a specific position', ->
      collection.reset ({id: i} for i in [0..2])

      addSpy = sinon.spy()
      collection.on 'add', addSpy
      resetSpy = sinon.spy()
      collection.on 'reset', resetSpy

      collection.addAtomic ({id: i} for i in [3..5]), at: 1
      expectOrder [0, 3, 4, 5, 1, 2]

      expect(addSpy).was.notCalled()
      expect(resetSpy).was.called()

    it 'should serialize the models', ->
      model1 = new Model id: 1, foo: 'foo'
      model2 = new Backbone.Model id: 2, bar: 'bar'
      collection = new Collection [model1, model2]
      expect(collection.serialize).to.be.a 'function'

      actual = collection.serialize()
      expected = [
        {id: 1, foo: 'foo'}
        {id: 2, bar: 'bar'}
      ]

      expect(actual.length).to.be expected.length

      expect(actual[0]).to.be.an 'object'
      expect(actual[0].id).to.be expected[0].id
      expect(actual[0].foo).to.be expected[0].foo

      expect(actual[1]).to.be.an 'object'
      expect(actual[1].id).to.be expected[1].id
      expect(actual[1].foo).to.be expected[1].foo

    describe 'Disposal', ->
      it 'should dispose itself correctly', ->
        expect(collection.dispose).to.be.a 'function'
        collection.dispose()

        expect(collection.length).to.be 0

        expect(collection.disposed).to.be true
        if Object.isFrozen
          expect(Object.isFrozen(collection)).to.be true

      it 'should fire a dispose event', ->
        disposeSpy = sinon.spy()
        collection.on 'dispose', disposeSpy

        collection.dispose()

        expect(disposeSpy).was.called()

      it 'should unsubscribe from Pub/Sub events', ->
        pubSubSpy = sinon.spy()
        collection.subscribeEvent 'foo', pubSubSpy

        collection.dispose()

        mediator.publish 'foo'
        expect(pubSubSpy).was.notCalled()

      it 'should remove all event handlers from itself', ->
        collectionBindSpy = sinon.spy()
        collection.on 'foo', collectionBindSpy

        collection.dispose()

        collection.trigger 'foo'
        expect(collectionBindSpy).was.notCalled()

      it 'should unsubscribe from other events', ->
        spy = sinon.spy()
        model = new Model
        collection.listenTo model, 'foo', spy

        collection.dispose()

        model.trigger 'foo'
        expect(spy).was.notCalled()

      it 'should reject the Deferred on disposal', ->
        collection.initDeferred()
        failSpy = sinon.spy()
        collection.fail failSpy

        collection.dispose()

        expect(collection.state()).to.be 'rejected'
        expect(failSpy).was.called()

      it 'should remove instance properties', ->
        collection.dispose()

        for prop in ['model', 'models', '_byId', '_byCid']
          expect(collection).not.to.have.own.property prop
