define [
  'underscore'
  'backbone'
  'chaplin/mediator'
  'chaplin/lib/strategist'
], (_, Backbone, mediator, Strategist) ->
  'use strict'

  describe 'Strategist', ->
    strategist = null

    beforeEach ->
      strategist = new Strategist()

    afterEach ->
      strategist.dispose()

    it 'should mixin a Backbone.Events', ->
      for own name, value of Backbone.Events
        expect(strategist[name]).to.be Backbone.Events[name]

    describe 'Strategy', ->
      it 'should accept a string', ->
        strategist.strategy = 'abort'
        strategist.initialize()

        expect(strategist.strategy).to.be.an 'object'
        expect(strategist.strategy.sync.read).to.be 'abort'
        expect(strategist.strategy.dispose.patch).to.be 'abort'

      it 'should accept only describing hooks', ->
        strategist.strategy =
          sync: 'stack'
          dispose: 'abort'
        strategist.initialize()

        expect(strategist.strategy.sync).to.be.an 'object'
        expect(strategist.strategy.dispose).to.be.an 'object'
        expect(strategist.strategy.sync.read).to.be 'stack'
        expect(strategist.strategy.sync.patch).to.be 'stack'
        expect(strategist.strategy.dispose.read).to.be 'abort'
        expect(strategist.strategy.dispose.patch).to.be 'abort'

      it 'should accept only describing methods with null as default', ->
        strategist.strategy =
          read: 'stack'
          patch: 'abort'
        strategist.initialize()

        expect(strategist.strategy.sync).to.be.an 'object'
        expect(strategist.strategy.dispose).to.be.an 'object'
        expect(strategist.strategy.sync.read).to.be 'stack'
        expect(strategist.strategy.sync.patch).to.be 'abort'
        expect(strategist.strategy.dispose.read).to.be 'stack'
        expect(strategist.strategy.dispose.patch).to.be 'abort'
        expect(strategist.strategy.dispose.delete).to.be 'null'

      it 'should accept the full object with null as default', ->
        strategist.strategy =
          sync:
            read: 'stack'

          dispose:
            patch: 'abort'

        strategist.initialize()

        expect(strategist.strategy.sync).to.be.an 'object'
        expect(strategist.strategy.dispose).to.be.an 'object'
        expect(strategist.strategy.sync.read).to.be 'stack'
        expect(strategist.strategy.sync.patch).to.be 'null'
        expect(strategist.strategy.dispose.read).to.be 'null'
        expect(strategist.strategy.dispose.patch).to.be 'abort'

    describe 'Inheritance', ->
      it 'should be extendable', ->
        expect(Strategist.extend).to.be.a 'function'

        DerivedStrategist = Strategist.extend()
        derivedStrategist = new DerivedStrategist()
        expect(derivedStrategist).to.be.a Strategist

        derivedStrategist.dispose()

      it 'should merge the handlers object', ->
        class DerivedStrategist extends Strategist
          handlers:
            'initialize':
              'newWave': -> # ...

        derived = new DerivedStrategist
          strategy: 'abort'

        expect(derived.handlers.initialize.newWave).to.be.a 'function'
        expect(derived.handlers['sync:before']).to.be.an 'object'
        expect(derived.handlers.dispose.abort).to.be.a 'function'

    describe 'Disposal', ->
      it 'should dispose itself correctly', ->
        expect(strategist.dispose).to.be.a 'function'
        strategist.dispose()

        expect(strategist.disposed).to.be true
        if Object.isFrozen
          expect(Object.isFrozen(strategist)).to.be true
