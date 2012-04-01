define [
  'mediator'
], (mediator) ->
  'use strict'

  describe 'mediator', ->
    #console.debug 'mediator spec'

    it 'should be a simple object', ->
      expect(typeof mediator).toEqual 'object'

    it 'should be sealed', ->
      return unless Object.isSealed
      expect(Object.isSealed(mediator)).toBe true

    it 'should have a router which is null', ->
      expect(mediator.router).toBeNull()

    it 'should have a user which is null', ->
      expect(mediator.user).toBeNull()

    it 'should have a readonly user', ->
      return  unless Object.defineProperty
      expect(->
        mediator.user = 'foo'
      ).toThrow()

    it 'should have a setUser method', ->
      expect(typeof mediator.setUser).toEqual 'function'

    it 'should have a user after calling setUser', ->
      user = {}
      mediator.setUser user
      expect(mediator.user).toBe user

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
        expect(desc.writable).toBe false

    it 'should be sealed', ->
      if Object.isSealed
        expect(Object.isSealed(mediator)).toBe true

    it 'should publish messages to subscribers', ->
      callback = jasmine.createSpy()
      eventName = 'foo'
      payload = 'payload'
      mediator.subscribe eventName, callback
      mediator.publish eventName, payload
      expect(callback).toHaveBeenCalledWith payload
      mediator.unsubscribe eventName, callback

    it 'should allow to unsubscribe to events', ->
      callback = jasmine.createSpy()
      eventName = 'foo'
      payload = 'payload'
      mediator.subscribe eventName, callback
      mediator.unsubscribe eventName, callback
      mediator.publish eventName, payload
      expect(callback).not.toHaveBeenCalledWith payload
