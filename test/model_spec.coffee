'use strict'

Backbone = require 'backbone'

sinon = require 'sinon'
chai = require 'chai'
chai.use require 'sinon-chai'
chai.should()

{expect} = chai
{EventBroker, mediator, Model} = require '../src/chaplin'

describe 'Model', ->
  model = null

  beforeEach ->
    model = new Model id: 1

  afterEach ->
    model.dispose()

  it 'should mixin a EventBroker', ->
    prototype = Model.prototype
    expect(prototype).to.contain.all.keys EventBroker

  it 'should return the attributes per default', ->
    expect(model.getAttributes()).to.deep.equal model.attributes

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

    expect(model.serialize()).to.deep.equal
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

  it 'should protect the original attributes when serializing', ->
    model1 = model.set number: 'one'
    model2 = new Model id: 2, number: 'two'
    model3 = new Backbone.Model id: 3, number: 'three'
    model1.set {model2}
    model1.set {model3}

    serialized = model1.serialize()

    # Try to tamper with the model attributes
    serialized.number =
    serialized.model2.number =
    serialized.model3.number = 'new'

    actual = [ model1, model2, model3 ].map (model) ->
      model.get 'number'

    # Original attributes remain unchanged
    expect(actual).to.deep.equal ['one', 'two', 'three']

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

    # expect(model1.serialize()).to.deep.equal
    #   number: 'one'
    #   model2:
    #     number: 'two'
    #   model3:
    #     number: 'three'
    #   collection: [
    #     number: 'four'
    #     number: 'five'
    #   ]

    expect(actual.number).to.equal 'one'
    expect(actual.model2).to.be.an 'object'
    expect(actual.model2.number).to.equal 'two'
    expect(actual.model3).to.be.an 'object'
    expect(actual.model3.number).to.equal 'three'

    expect(actual.collection).to.be.an 'array'
    expect(actual.collection.length).to.equal 2
    expect(actual.collection[0].number).to.equal 'four'
    expect(actual.collection[1].number).to.equal 'five'

  describe 'Disposal', ->
    it 'should dispose itself correctly', ->
      expect(model.disposed).to.be.false
      expect(model.dispose).to.be.a 'function'
      model.dispose()

      expect(model.disposed).to.be.true
      expect(model).to.be.frozen

    it 'should fire a dispose event', ->
      disposeSpy = sinon.spy()

      model.on 'dispose', disposeSpy
      model.dispose()

      disposeSpy.should.have.been.called

    it 'should unsubscribe from Pub/Sub events', ->
      pubSubSpy = sinon.spy()

      model.subscribeEvent 'foo', pubSubSpy
      model.dispose()
      mediator.publish 'foo'

      pubSubSpy.should.not.have.been.called

    it 'should remove all event handlers from itself', ->
      modelBindSpy = sinon.spy()

      model.on 'foo', modelBindSpy
      model.dispose()
      model.trigger 'foo'

      modelBindSpy.should.not.have.been.called

    it 'should unsubscribe from other events', ->
      spy = sinon.spy()
      model2 = new Model()
      model.listenTo model2, 'foo', spy
      model.dispose()

      model2.trigger 'foo'
      spy.should.not.have.been.called

    it 'should remove instance properties', ->
      model.dispose()

      keys = [
        'collection',
        'attributes', 'changed'
        '_escapedAttributes', '_previousAttributes',
        '_silent', '_pending',
        '_callbacks'
      ]

      for key in keys
        expect(model).not.to.have.ownProperty key
