define [
  'underscore'
  'backbone'
  'chaplin/mediator'
  'chaplin/models/model'
  'chaplin/lib/event_broker'
], (_, Backbone, mediator, Model, EventBroker) ->
  'use strict'

  describe 'Model', ->
    model = null

    beforeEach ->
      model = new Model id: 1

    afterEach ->
      model.dispose()

    it 'should mixin a EventBroker', ->
      for own name, value of EventBroker
        expect(model[name]).to.be EventBroker[name]

    it 'should initialize a Deferred', ->
      expect(model.initDeferred).to.be.a 'function'
      model.initDeferred()
      for method in ['done', 'fail', 'progress', 'state', 'promise']
        expect(typeof model[method]).to.be 'function'
      expect(model.state()).to.be 'pending'

    it 'should return the attributes per default', ->
      expect(model.getAttributes()).to.be model.attributes

    it 'should serialize the attributes', ->
      model1 = model.set number: 'one'
      model2 = new Model id: 2, number: 'two'
      model3 = new Model id: 3, number: 'three'
      model4 = new Model id: 4, number: 'four'
      model5 = new Model id: 5, number: 'five'
      collection = new Backbone.Collection [model4, model5]
      model1.set {model2}
      model2.set {model3}
      model2.set {collection}
      model2.set {model2} # Circular fun!
      model3.set {model2} # Even more fun!
      model4.set {model2} # Even more fun!

      # Reference tree:
      # model1
      #   model2
      #     model3
      #       model2
      #     collection
      #       model4
      #         model2
      #       model5
      #     model2

      actual = model.serialize()

      expected =
        id: 1
        number: 'one'
        model2:
          id: 2
          number: 'two'
          # Circular references are nullified
          model2: null
          model3:
            id: 3
            number: 'three'
            # Circular references are nullified
            model2: null
          collection: [
            {
              id: 4
              number: 'four'
              # Circular references are nullified
              model2: null
            },
            {
              id: 5
              number: 'five'
            }
          ]

      expect(actual).to.be.an 'object'
      expect(actual.number).to.be expected.number

      expect(actual.model2).to.be.an 'object'
      expect(actual.model2.number).to.be expected.model2.number
      expect(actual.model2.model2).to.be expected.model2.model2

      actualCollection = actual.model2.collection
      expectedCollection = expected.model2.collection
      expect(actualCollection).to.be.an 'array'
      expect(actualCollection[0].number).to.be expectedCollection[0].number
      expect(actualCollection[0].model2).to.be expectedCollection[0].model2
      expect(actualCollection[1].number).to.be expectedCollection[1].number

      expect(actual.model2.model3).to.be.an 'object'
      expect(actual.model2.model3.number).to.be expected.model2.model3.number
      expect(actual.model2.model3.model2).to.be expected.model2.model3.model2

    it 'should protect the original attributes when serializing', ->
      model1 = model.set number: 'one'
      model2 = new Model id: 2, number: 'two'
      model3 = new Backbone.Model id: 3, number: 'three'
      model1.set {model2}
      model1.set {model3}

      serialized = model1.serialize()
      # Try to tamper with the model attributes
      serialized.number = 'new'
      serialized.model2.number = 'new'
      serialized.model3.number = 'new'

      # Original attributes remain unchanged
      expect(model1.get('number')).to.be 'one'
      expect(model2.get('number')).to.be 'two'
      expect(model3.get('number')).to.be 'three'

    it 'should serialize nested Backbone models and collections', ->
      model1 = model.set number: 'one'
      model2 = new Model id: 2, number: 'two'
      model3 = new Backbone.Model id: 3, number: 'three'
      collection = new Backbone.Collection [
        new Model id: 4, number: 'four'
        new Backbone.Model id: 5, number: 'five'
      ]

      model1.set {model2}
      model1.set {model3}
      model1.set {collection}

      actual = model1.serialize()

      expect(actual.number).to.be 'one'
      expect(actual.model2).to.be.an 'object'
      expect(actual.model2.number).to.be 'two'
      expect(actual.model3).to.be.an 'object'
      expect(actual.model3.number).to.be 'three'

      expect(actual.collection).to.be.an 'array'
      expect(actual.collection.length).to.be 2
      expect(actual.collection[0].number).to.be 'four'
      expect(actual.collection[1].number).to.be 'five'

    describe 'Disposal', ->
      it 'should dispose itself correctly', ->
        expect(model.dispose).to.be.a 'function'
        model.dispose()

        expect(model.disposed).to.be true
        if Object.isFrozen
          expect(Object.isFrozen(model)).to.be true

      it 'should fire a dispose event', ->
        disposeSpy = sinon.spy()
        model.on 'dispose', disposeSpy

        model.dispose()

        expect(disposeSpy).was.called()

      it 'should unsubscribe from Pub/Sub events', ->
        pubSubSpy = sinon.spy()
        model.subscribeEvent 'foo', pubSubSpy

        model.dispose()

        mediator.publish 'foo'
        expect(pubSubSpy).was.notCalled()

      it 'should remove all event handlers from itself', ->
        modelBindSpy = sinon.spy()
        model.on 'foo', modelBindSpy

        model.dispose()

        model.trigger 'foo'
        expect(modelBindSpy).was.notCalled()

      it 'should unsubscribe from other events', ->
        spy = sinon.spy()
        model2 = new Model
        model.listenTo model2, 'foo', spy

        model.dispose()

        model2.trigger 'foo'
        expect(spy).was.notCalled()

      it 'should reject the Deferred on disposal', ->
        model.initDeferred()
        failSpy = sinon.spy()
        model.fail failSpy

        model.dispose()

        expect(model.state()).to.be 'rejected'
        expect(failSpy).was.called()

      it 'should remove instance properties', ->
        model.dispose()

        properties = [
          'collection',
          'attributes', 'changed'
          '_escapedAttributes', '_previousAttributes',
          '_silent', '_pending',
          '_callbacks'
        ]
        for prop in properties
          expect(model).not.to.have.own.property prop
