define [
  'underscore'
  'chaplin/lib/support'
  'chaplin/mediator'
  'chaplin/models/model'
], (_, support, mediator, Model) ->
  'use strict'

  describe 'mediator', ->
    it 'should be a simple object', ->
      expect(mediator).to.be.an 'object'

    it 'should have Pub/Sub methods', ->
      expect(mediator.subscribe).to.be.a 'function'
      expect(mediator.unsubscribe).to.be.a 'function'
      expect(mediator.publish).to.be.a 'function'

    it 'should have readonly Pub/Sub and Resp/Req methods', ->
      return unless support.propertyDescriptors and
        Object.getOwnPropertyDescriptor
      methods = [
        'subscribe', 'unsubscribe', 'publish',
        'setHandler', 'execute', 'removeHandlers'
      ]
      for property in methods
        desc = Object.getOwnPropertyDescriptor(mediator, property)
        expect(desc.enumerable).to.be true
        expect(desc.writable).to.be false
        expect(desc.configurable).to.be false

    it 'should publish messages to subscribers', ->
      spy = sinon.spy()
      eventName = 'foo'
      payload = 'payload'

      mediator.subscribe eventName, spy
      mediator.publish eventName, payload

      expect(spy).was.calledWith payload
      mediator.unsubscribe eventName, spy

    it 'should allow to unsubscribe to events', ->
      spy = sinon.spy()
      eventName = 'foo'
      payload = 'payload'

      mediator.subscribe eventName, spy
      mediator.unsubscribe eventName, spy
      mediator.publish eventName, payload

      expect(spy).was.neverCalledWith payload

    it 'should have response / request methods', ->
      expect(mediator.setHandler).to.be.a 'function'
      expect(mediator.execute).to.be.a 'function'
      expect(mediator.removeHandlers).to.be.a 'function'

    it 'should allow to set and execute handlers', ->
      resp = 'austrian'
      spy = sinon.stub().returns resp
      name = 'ancap'
      mediator.setHandler name, spy
      expect(mediator.execute name).to.be resp

    it 'should support sealing itself', ->
      strict = do (-> 'use strict'; !this)
      return unless strict

      expect(mediator.seal).to.be.a 'function'
      old = Object.seal
      Object.seal = undefined
      mediator.seal()
      expect(-> mediator.a = 1; delete mediator.a).to.not.throwError()
      Object.seal = old
      mediator.seal()
      expect(-> mediator.a = 1).to.throwError()
