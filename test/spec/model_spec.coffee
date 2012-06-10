define [
  'chaplin/mediator'
  'chaplin/models/model'
  'chaplin/lib/subscriber'
  'chaplin/lib/sync_machine'
], (mediator, Model, Subscriber, SyncMachine) ->
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

    it 'should initialize a Deferred', ->
      expect(typeof model.initDeferred).toBe 'function'
      model.initDeferred()
      for method in ['done', 'fail', 'progress', 'state', 'promise']
        expect(typeof model[method]).toBe 'function'
      expect(model.state()).toBe 'pending'

    it 'should initialize a SyncMachine', ->
      expect(typeof model.initSyncMachine).toBe 'function'
      model.initSyncMachine()
      for own name, value of SyncMachine
        if typeof value is 'function'
          expect(model[name]).toBe value
      expect(model.syncState()).toBe 'unsynced'

    it 'should return the attributes per default', ->
      expect(model.getAttributes()).toBe model.attributes

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
      model2.set collection: collection
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
          collection: [
            {foo: 'foo'},
            {baz: 'baz'}
          ]

      #console.debug 'passedTemplateData', d

      expect(typeof d).toBe 'object'
      expect(d.foo).toBe e.foo

      expect(typeof d.model2).toBe 'object'
      expect(d.model2.bar).toBe e.model2.bar
      expect(d.model2.model2).toBe e.model2.model2

      expect(typeof d.model2.collection).toBe 'object'
      expect(d.model2.collection[0].foo).toBe e.model2.collection[0].foo
      expect(d.model2.collection[1].baz).toBe e.model2.collection[1].baz

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
