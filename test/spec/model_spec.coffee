define [
  'underscore'
  'chaplin/mediator'
  'chaplin/models/model'
  'chaplin/lib/event_broker'
], (_, mediator, Model, EventBroker) ->
  'use strict'

  describe 'Model', ->
    #console.debug 'Model spec'

    model = null

    beforeEach ->
      model = new Model id: 1, foo: 'foo'

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
      model1 = model
      model2 = new Model
        id: 2
        bar: 'bar'
      model3 = new Model
        id: 3
        qux: 'qux'
      model4 = new Model
        id: 4
        foo: 'foo'
      model5 = new Model
        id: 5
        baz: 'baz'
      collection = new Backbone.Collection [model4, model5]
      model1.set model2: model2
      model2.set model3: model3
      model2.set {collection}
      model2.set model2: model2 # Circular fun!
      model3.set model2: model2 # Even more fun!

      actual = model.serialize()

      expected =
        foo: 'foo'
        model2:
          bar: 'bar'
          # Circular references are nullified
          model2: null
          model3:
            qux: 'qux'
            # Circular references are nullified
            model2: null
          collection: [
            {foo: 'foo'},
            {baz: 'baz'}
          ]

      #console.debug 'passedTemplateData', d

      expect(actual).to.be.an 'object'
      expect(actual.foo).to.be expected.foo

      expect(actual.model2).to.be.an 'object'
      expect(actual.model2.bar).to.be expected.model2.bar
      expect(actual.model2.model2).to.be expected.model2.model2

      expect(actual.model2.collection).to.be.an 'array'
      expect(actual.model2.collection[0].foo).to.be(
        expected.model2.collection[0].foo
      )
      expect(actual.model2.collection[1].baz).to.be(
        expected.model2.collection[1].baz
      )

      expect(actual.model2.model3).to.be.an 'object'
      expect(actual.model2.model3.qux).to.be expected.model2.model3.qux
      expect(actual.model2.model3.model2).to.be expected.model2.model3.model2

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
