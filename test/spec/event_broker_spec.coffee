define [
  'underscore'
  'backbone'
  'chaplin/mediator'
  'chaplin/lib/event_broker'
], (_, Backbone, mediator, EventBroker) ->
  'use strict'

  describe 'EventBroker', ->
    # Create a simple object which mixes in the EventBroker
    eventBroker = _.extend {}, EventBroker

    it 'should subscribe to events', ->
      expect(eventBroker.subscribeEvent).to.be.a 'function'

      # We could mock Backbone.trigger here and test if it was called,
      # well, better testing the outcome.
      type = 'eventBrokerTest'
      spy = sinon.spy()
      eventBroker.subscribeEvent type, spy

      Backbone.trigger type, 1, 2, 3, 4
      expect(spy).was.calledOnce()
      expect(spy).was.calledWith 1, 2, 3, 4
      expect(spy).was.calledOn eventBroker

      Backbone.off type, spy

    it 'should not subscribe the same handler twice', ->
      type = 'eventBrokerTest'
      spy = sinon.spy()
      eventBroker.subscribeEvent type, spy
      eventBroker.subscribeEvent type, spy

      Backbone.trigger type, 1, 2, 3, 4
      expect(spy).was.calledOnce()
      expect(spy).was.calledWith 1, 2, 3, 4
      expect(spy).was.calledOn eventBroker

      Backbone.off type, spy

    it 'should check the params when subscribing', ->
      expect(-> eventBroker.subscribeEvent()).to.throwError()
      expect(-> eventBroker.subscribeEvent(undefined, undefined)).to.throwError()
      expect(-> eventBroker.subscribeEvent(1234, ->)).to.throwError()
      expect(-> eventBroker.subscribeEvent('event', {})).to.throwError()

    it 'should unsubscribe from events', ->
      expect(eventBroker.unsubscribeEvent).to.be.a 'function'

      type = 'eventBrokerTest'
      spy = sinon.spy()
      eventBroker.subscribeEvent type, spy
      eventBroker.unsubscribeEvent type, spy

      Backbone.trigger type
      expect(spy).was.notCalled()

    it 'should check the params when unsubscribing', ->
      expect(-> eventBroker.unsubscribeEvent()).to.throwError()
      expect(-> eventBroker.unsubscribeEvent(undefined, undefined)).to.throwError()
      expect(-> eventBroker.unsubscribeEvent(1234, ->)).to.throwError()
      expect(-> eventBroker.unsubscribeEvent('event', {})).to.throwError()

    it 'should unsubscribe from all events', ->
      expect(eventBroker.unsubscribeAllEvents).to.be.a 'function'

      spy = sinon.spy()
      unrelatedHandler = sinon.spy()
      context = {}

      eventBroker.subscribeEvent 'one', spy
      eventBroker.subscribeEvent 'two', spy
      eventBroker.subscribeEvent 'three', spy
      Backbone.on 'four', unrelatedHandler
      Backbone.on 'four', unrelatedHandler, context

      eventBroker.unsubscribeAllEvents()
      Backbone.trigger 'one'
      Backbone.trigger 'two'
      Backbone.trigger 'three'
      Backbone.trigger 'four'
      expect(spy).was.notCalled()
      # Ensure other handlers remain untouched
      expect(unrelatedHandler).was.calledTwice()

      Backbone.off 'four', unrelatedHandler

    it 'should publish events', ->
      expect(eventBroker.publishEvent).to.be.a 'function'

      type = 'eventBrokerTest'
      spy = sinon.spy()
      Backbone.on type, spy

      eventBroker.publishEvent type, 1, 2, 3, 4
      expect(spy).was.calledOnce()
      expect(spy).was.calledWith 1, 2, 3, 4

      Backbone.off type, spy

    it 'should check the params when publishing events', ->
      expect(-> eventBroker.publishEvent()).to.throwError()
      expect(-> eventBroker.publishEvent(null)).to.throwError()
      expect(-> eventBroker.publishEvent(undefined)).to.throwError()
      expect(-> eventBroker.publishEvent(1234)).to.throwError()
      expect(-> eventBroker.publishEvent({})).to.throwError()

    it 'should interop with Backbone global events', ->
      spy = sinon.spy()
      eventBroker.subscribeEvent 'stuff', spy
      Backbone.trigger 'stuff', 'hello', 'world'
      expect(spy).was.calledOnce()
      expect(spy).was.calledWith 'hello', 'world'

      Backbone.on 'other-stuff', spy
      eventBroker.publishEvent 'other-stuff', 'world', 'hello'
      expect(spy).was.calledTwice()
      expect(spy).was.calledWith 'world', 'hello'
