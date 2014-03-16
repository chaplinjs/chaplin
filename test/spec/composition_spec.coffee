define [
  'underscore'
  'chaplin/mediator'
  'chaplin/lib/event_broker'
  'chaplin/lib/composition'
  'chaplin/models/model'
], (_, mediator, EventBroker, Composition, Model) ->
  'use strict'

  describe 'Composition', ->

    composition = null

    beforeEach ->
      # Instantiate
      composition = new Composition()

    afterEach ->
      # Dispose
      composition.dispose()
      composition = null

    # mixin
    # -----

    it 'should mixin a EventBroker', ->
      for own name, value of EventBroker
        expect(composition[name]).to.be EventBroker[name]

    # initialize
    # ----------

    it 'should initialize', ->
      expect(composition.initialize).to.be.a 'function'
      composition.initialize()
      expect(composition.stale()).to.be false

    # disposal
    # --------

    it 'should dispose itself and all objects', ->
      model1 = new Model()
      model2 = new Model()
      composition.object = model1
      composition.randomProperty = model2

      expect(composition.dispose).to.be.a 'function'
      composition.dispose()

      expect(model1.disposed).to.be true
      expect(model2.disposed).to.be true
      expect(composition.object).to.be null
      expect(composition).not.to.have.property 'randomProperty'

      expect(composition.disposed).to.be true
      expect(Object.isFrozen(composition)).to.be true if Object.isFrozen

    # extensible
    # ----------

    it 'should be extendable', ->
      expect(Composition.extend).to.be.a 'function'

      composition.dispose()
      DerivedComposition = Composition.extend()
      composition = new DerivedComposition()
      expect(composition).to.be.a Composition
