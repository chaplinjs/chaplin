define [
  'chaplin/mediator'
  'chaplin/models/model'
  'chaplin/lib/subscriber'
], (mediator, Model, Subscriber) ->
  'use strict'

  describe 'Model', ->
    #console.debug 'Model spec'

    model = null

    beforeEach ->
      model = new Model id: 1, foo: 'foo'

    afterEach ->
      model.dispose()

    it 'should mixin a Subscriber', ->
      for own name, value of Subscriber
        expect(model[name]).toBe Subscriber[name]

    it 'should serialize', ->
      model1 = model
      model2 = new Model
        id: 2
        bar: 'bar'
      model3 = new Model
        id: 3
        qux: 'qux'
      model1.set model2: model2
      model2.set model3: model3
      model2.set model2: model2 # Circular fun!
      model3.set model2: model2 # Even more fun!

      d = model.serialize()

      # Expected
      e =
        foo: 'foo'
        model2:
          bar: 'bar'
          # Circular references are nullified
          model2: null
          model3:
            qux: 'qux'
            # Circular references are nullified
            model2: null

      #console.debug 'passedTemplateData', d

      expect(typeof d).toBe 'object'
      expect(d.foo).toBe e.foo

      expect(typeof d.model2).toBe 'object'
      expect(d.model2.bar).toBe e.model2.bar
      expect(d.model2.model2).toBe e.model2.model2

      expect(typeof d.model2.model3).toBe 'object'
      expect(d.model2.model3.qux).toBe e.model2.model3.qux
      expect(d.model2.model3.model2).toBe e.model2.model3.model2

    it 'should dispose itself correctly', ->
      expect(typeof model.dispose).toBe 'function'
      model.dispose()

      expect(model.disposed).toBe true
      if Object.isFrozen
        expect(Object.isFrozen(model)).toBe true

    it 'should fire a dispose event', ->
      disposeSpy = jasmine.createSpy()
      model.on 'dispose', disposeSpy

      model.dispose()

      expect(disposeSpy).toHaveBeenCalled()

    it 'should unsubscribe from Pub/Sub events', ->
      pubSubSpy = jasmine.createSpy()
      model.subscribeEvent 'foo', pubSubSpy

      model.dispose()

      mediator.publish 'foo'
      expect(pubSubSpy).not.toHaveBeenCalled()

    it 'should remove all event handlers from itself', ->
      modelBindSpy = jasmine.createSpy()
      model.on 'foo', modelBindSpy

      model.dispose()

      model.trigger 'foo'
      expect(modelBindSpy).not.toHaveBeenCalled()

    it 'should reject the Deferred on disposal', ->
      model.initDeferred()
      failSpy = jasmine.createSpy()
      model.fail failSpy

      model.dispose()

      expect(model.state()).toBe 'rejected'
      expect(failSpy).toHaveBeenCalled()

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
        expect(_(model).has prop).toBe false
