define [
  'underscore'
  'chaplin/mediator'
  'chaplin/lib/event_broker'
  'chaplin/lib/composition'
], (_, mediator, EventBroker, Composition) ->
  'use strict'

  describe 'Composition', ->

    composition = null

    beforeEach ->
      # Instantiate
      composition = new Composition

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
      expect(composition.item).to.be composition

    # disposal
    # --------

    it 'should dispose itself correctly', ->
      expect(composition.dispose).to.be.a 'function'
      composition.dispose()

      for prop in ['compositions']
        expect(composition.hasOwnProperty prop).to.not.be.ok()

      expect(composition.disposed).to.be true
      expect(Object.isFrozen(composition)).to.be true if Object.isFrozen

    # extensible
    # ----------

    it 'should be extendable', ->
      expect(Composition.extend).to.be.a 'function'

      Derivedcomposition = Composition.extend()
      derivedcomposition = new Derivedcomposition()
      expect(derivedcomposition).to.be.a Composition

      derivedcomposition.dispose()
