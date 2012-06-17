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
      expect(_.isObject mediator).toBe true

    it 'should have Pub/Sub methods', ->
      expect(typeof mediator.subscribe).toBe 'function'
      expect(typeof mediator.unsubscribe).toBe 'function'
      expect(typeof mediator.publish).toBe 'function'

    it 'should have readonly Pub/Sub methods', ->
      return unless support.propertyDescriptors and
        Object.getOwnPropertyDescriptor
      methods = ['subscribe', 'unsubscribe', 'publish',
        'on', 'off', 'trigger']
      _(methods).forEach (property) ->
        desc = Object.getOwnPropertyDescriptor(mediator, property)
        expect(desc.enumerable).toBe true
        expect(desc.writable).toBe false
        expect(desc.configurable).toBe false

    it 'should publish messages to subscribers', ->
      spy = jasmine.createSpy()
      eventName = 'foo'
      payload = 'payload'

      mediator.subscribe eventName, spy
      mediator.publish eventName, payload

      expect(spy).toHaveBeenCalledWith payload
      mediator.unsubscribe eventName, spy

    it 'should allow to unsubscribe to events', ->
      spy = jasmine.createSpy()
      eventName = 'foo'
      payload = 'payload'

      mediator.subscribe eventName, spy
      mediator.unsubscribe eventName, spy
      mediator.publish eventName, payload

      expect(spy).not.toHaveBeenCalledWith payload
