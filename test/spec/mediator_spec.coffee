define [
  'underscore'
  'chaplin/lib/support'
  'chaplin/mediator'
  'chaplin/models/model'
], (_, support, mediator, Model) ->
  'use strict'

  describe 'mediator', ->
    #console.debug 'mediator spec'

    it 'should be a simple object', ->
      expect(mediator).to.be.an 'object'

    it 'should have Pub/Sub methods', ->
      expect(mediator.subscribe).to.be.a 'function'
      expect(mediator.unsubscribe).to.be.a 'function'
      expect(mediator.publish).to.be.a 'function'

    it 'should have readonly Pub/Sub methods', ->
      return unless support.propertyDescriptors and
        Object.getOwnPropertyDescriptor
      methods = ['subscribe', 'unsubscribe', 'publish',
        'on']
      _(methods).forEach (property) ->
        desc = Object.getOwnPropertyDescriptor(mediator, property)
        expect(desc.enumerable).to.be.ok()
        expect(desc.writable).to.not.be.ok()
        expect(desc.configurable).to.not.be.ok()

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
