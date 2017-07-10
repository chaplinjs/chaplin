'use strict'
sinon = require 'sinon'
{mediator, Model} = require '../src/chaplin'

describe 'mediator', ->
  it 'should be a simple object', ->
    expect(mediator).to.be.an 'object'

  it 'should have seal method and be sealed', ->
    expect(mediator.seal).to.be.a 'function'
    expect(mediator).to.be.sealed

  it 'should have Pub/Sub methods', ->
    expect(mediator.subscribe).to.be.a 'function'
    expect(mediator.subscribeOnce).to.be.a 'function'
    expect(mediator.unsubscribe).to.be.a 'function'
    expect(mediator.publish).to.be.a 'function'

  it 'should have readonly Pub/Sub and Resp/Req methods', ->
    methods = [
      'subscribe', 'subscribeOnce', 'unsubscribe', 'publish',
      'setHandler', 'execute', 'removeHandlers'
    ]

    for method in methods
      expect(mediator).to.have.ownPropertyDescriptor method,
        value: mediator[method]
        writable: false
        enumerable: true
        configurable: false

  it 'should publish messages to subscribers', ->
    spy = sinon.spy()
    eventName = 'foo'
    payload = 'payload'

    mediator.subscribe eventName, spy
    mediator.publish eventName, payload

    spy.should.have.been.calledOnce
    mediator.unsubscribe eventName, spy

  it 'should publish messages to subscribers once', ->
    spy = sinon.spy()
    eventName = 'foo'
    payload = 'payload'

    mediator.subscribeOnce eventName, spy
    mediator.publish eventName, payload
    mediator.publish eventName, 'second'

    spy.should.have.been.calledOnce
    spy.should.have.been.calledWith payload

  it 'should allow to unsubscribe to events', ->
    spy = sinon.spy()
    eventName = 'foo'
    payload = 'payload'

    mediator.subscribe eventName, spy
    mediator.unsubscribe eventName, spy
    mediator.publish eventName, payload

    spy.should.not.have.been.calledWith payload

  it 'should have response / request methods', ->
    expect(mediator.setHandler).to.be.a 'function'
    expect(mediator.execute).to.be.a 'function'
    expect(mediator.removeHandlers).to.be.a 'function'

  it 'should allow to set and execute handlers', ->
    response = 'austrian'
    spy = sinon.stub().returns response
    name = 'ancap'

    mediator.setHandler name, spy
    expect(mediator.execute name).to.equal response
