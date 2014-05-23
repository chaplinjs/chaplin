define [
  'underscore'
  'chaplin/mediator'
  'chaplin/lib/event_broker'
], (_, mediator, EventBroker) ->
  'use strict'

  describe 'EventBroker', ->
    # Create a simple object which mixes in the EventBroker
    eventBroker = _.extend {}, EventBroker

    it 'should subscribe to events', ->
      expect(eventBroker.subscribeEvent).to.be.a 'function'

      # We could mock mediator.publish here and test if it was called,
      # well, better testing the outcome.
      type = 'eventBrokerTest'
      spy = sinon.spy()
      eventBroker.subscribeEvent type, spy

      mediator.publish type, 1, 2, 3, 4
      expect(spy).was.calledOnce()
      expect(spy).was.calledWith 1, 2, 3, 4
      expect(spy).was.calledOn eventBroker

      mediator.unsubscribe type, spy

    it 'should not subscribe the same handler twice', ->
      type = 'eventBrokerTest'
      spy = sinon.spy()
      eventBroker.subscribeEvent type, spy
      eventBroker.subscribeEvent type, spy

      mediator.publish type, 1, 2, 3, 4
      expect(spy).was.calledOnce()
      expect(spy).was.calledWith 1, 2, 3, 4
      expect(spy).was.calledOn eventBroker

      mediator.unsubscribe type, spy

    it 'should unsubscribe from events', ->
      expect(eventBroker.unsubscribeEvent).to.be.a 'function'

      type = 'eventBrokerTest'
      spy = sinon.spy()
      eventBroker.subscribeEvent type, spy
      eventBroker.unsubscribeEvent type, spy

      mediator.publish type
      expect(spy).was.notCalled()

    it 'should unsubscribe from all events', ->
      expect(eventBroker.unsubscribeAllEvents).to.be.a 'function'

      spy = sinon.spy()
      unrelatedHandler = sinon.spy()
      context = {}

      eventBroker.subscribeEvent 'one', spy
      eventBroker.subscribeEvent 'two', spy
      eventBroker.subscribeEvent 'three', spy
      mediator.subscribe 'four', unrelatedHandler
      mediator.subscribe 'four', unrelatedHandler, context

      eventBroker.unsubscribeAllEvents()
      mediator.publish 'one'
      mediator.publish 'two'
      mediator.publish 'three'
      mediator.publish 'four'
      expect(spy).was.notCalled()
      # Ensure other handlers remain untouched
      expect(unrelatedHandler).was.calledTwice()

      mediator.unsubscribe 'four', unrelatedHandler

    it 'should publish events', ->
      expect(eventBroker.publishEvent).to.be.a 'function'

      type = 'eventBrokerTest'
      spy = sinon.spy()
      mediator.subscribe type, spy

      eventBroker.publishEvent type, 1, 2, 3, 4
      expect(spy).was.calledOnce()
      expect(spy).was.calledWith 1, 2, 3, 4

      mediator.unsubscribe type, spy
