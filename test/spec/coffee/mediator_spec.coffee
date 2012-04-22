define [
  'chaplin/lib/create_mediator',
  'chaplin/models/model'
], (createMediator, Model) ->
  'use strict'

  mediator = createMediator
    createUserProperty: true

  describe 'mediator', ->
    #console.debug 'mediator spec'

    it 'should be a simple object', ->
      expect(typeof mediator).toEqual 'object'

    it 'should have Pub/Sub methods', ->
      expect(typeof mediator.subscribe).toEqual 'function'
      expect(typeof mediator.unsubscribe).toEqual 'function'
      expect(typeof mediator.publish).toEqual 'function'

    it 'should have readonly Pub/Sub methods', ->
      return unless Object.defineProperty
      methods = [ 'subscribe', 'unsubscribe', 'publish' ]
      methods.forEach (property) ->
        expect(->
          mediator[property] = 'foo'
        ).toThrow()

      return unless Object.getOwnPropertyDescriptor
      methods.forEach (property) ->
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

    it 'should have a user which is null', ->
      expect(mediator.user).toBeNull()

    it 'should have a readonly user', ->
      return unless Object.defineProperty
      expect(->
        mediator.user = 'foo'
      ).toThrow()

    it 'should have a setUser method', ->
      expect(typeof mediator.setUser).toEqual 'function'

    it 'should have a user after calling setUser', ->
      user = new Model
      mediator.setUser user
      expect(mediator.user).toBe user
