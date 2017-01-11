import sinon from 'sinon'
import chai from 'chai'
import sinonChai from 'sinon-chai'
import Chaplin from '../src/chaplin'

chai.use sinonChai
chai.should()

{expect} = chai
{EventBroker, mediator} = Chaplin

describe 'EventBroker', ->
  # Create a simple object which mixes in the EventBroker
  eventBroker = Object.assign {}, EventBroker

  it 'should subscribe to events', ->
    expect(eventBroker.subscribeEvent).to.be.a 'function'

    # We could mock mediator.publish here and test if it was called,
    # well, better testing the outcome.
    type = 'eventBrokerTest'
    spy = sinon.spy()
    eventBroker.subscribeEvent type, spy

    mediator.publish type, 1, 2, 3, 4
    spy.should.have.been.calledOnce
    spy.should.have.been.calledWith 1, 2, 3, 4
    spy.should.have.been.calledOn eventBroker

    mediator.unsubscribe type, spy

  it 'should not subscribe the same handler twice', ->
    type = 'eventBrokerTest'
    spy = sinon.spy()
    eventBroker.subscribeEvent type, spy
    eventBroker.subscribeEvent type, spy

    mediator.publish type, 1, 2, 3, 4
    spy.should.have.been.calledOnce
    spy.should.have.been.calledWith 1, 2, 3, 4
    spy.should.have.been.calledOn eventBroker

    mediator.unsubscribe type, spy

  it 'should not call `once` handler twice', ->
    type = 'eventBrokerTest'
    spy = sinon.spy()
    eventBroker.subscribeEventOnce type, spy
    eventBroker.subscribeEventOnce type, spy

    mediator.publish type, 1, 2, 3, 4
    mediator.publish type, 5, 6, 7, 8

    spy.should.have.been.calledOnce
    spy.should.have.been.calledWith 1, 2, 3, 4
    spy.should.have.been.calledOn eventBroker

  it 'should unsubscribe from events', ->
    expect(eventBroker.unsubscribeEvent).to.be.a 'function'

    type = 'eventBrokerTest'
    spy = sinon.spy()
    eventBroker.subscribeEvent type, spy
    eventBroker.unsubscribeEvent type, spy

    mediator.publish type
    spy.should.not.have.been.called

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

    spy.should.not.have.been.called
    # Ensure other handlers remain untouched
    unrelatedHandler.should.have.been.calledTwice
    mediator.unsubscribe 'four', unrelatedHandler

  it 'should publish events', ->
    expect(eventBroker.publishEvent).to.be.a 'function'

    type = 'eventBrokerTest'
    spy = sinon.spy()
    mediator.subscribe type, spy

    eventBroker.publishEvent type, 1, 2, 3, 4
    spy.should.have.been.calledOnce
    spy.should.have.been.calledWith 1, 2, 3, 4

    mediator.unsubscribe type, spy
