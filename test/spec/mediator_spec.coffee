define [
  'chaplin'
], (Chaplin) ->
  'use strict'

  describe 'mediator', ->
    #console.debug 'mediator spec'

    it 'should be a simple object', ->
      expect(typeof Chaplin.mediator).toBe 'object'

    it 'should have Pub/Sub methods', ->
      expect(typeof Chaplin.mediator.subscribe).toBe 'function'
      expect(typeof Chaplin.mediator.unsubscribe).toBe 'function'
      expect(typeof Chaplin.mediator.publish).toBe 'function'

    it 'should have readonly Pub/Sub methods', ->
      return unless Chaplin.support.propertyDescriptors and
        Object.getOwnPropertyDescriptor
      methods = ['subscribe', 'unsubscribe', 'publish',
        'on', 'off', 'trigger']
      _(methods).forEach (property) ->
        desc = Object.getOwnPropertyDescriptor(Chaplin.mediator, property)
        expect(desc.enumerable).toBe true
        expect(desc.writable).toBe false
        expect(desc.configurable).toBe false

    it 'should publish messages to subscribers', ->
      spy = jasmine.createSpy()
      eventName = 'foo'
      payload = 'payload'

      Chaplin.mediator.subscribe eventName, spy
      Chaplin.mediator.publish eventName, payload

      expect(spy).toHaveBeenCalledWith payload
      Chaplin.mediator.unsubscribe eventName, spy

    it 'should allow to unsubscribe to events', ->
      spy = jasmine.createSpy()
      eventName = 'foo'
      payload = 'payload'

      Chaplin.mediator.subscribe eventName, spy
      Chaplin.mediator.unsubscribe eventName, spy
      Chaplin.mediator.publish eventName, payload

      expect(spy).not.toHaveBeenCalledWith payload
