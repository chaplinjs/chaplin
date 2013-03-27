'use strict'

_ = require 'underscore'
Delayer = require 'chaplin/lib/delayer'

describe 'Delayer', ->
  # Set up an object which mixes in Delayer
  delayer = {}
  _(delayer).extend Delayer

  it 'should be a simple object', ->
    expect(Delayer).to.be.an 'object'

  it 'should allow to set a timeout ', (done) ->
    expect(delayer.setTimeout).to.be.a 'function'
    handle = delayer.setTimeout 'foo', 1, ->
      done()
    expect(handle).to.be.a 'number'

  it 'should create a timeout handle store', (done) ->
    expect(delayer.timeouts).to.be.an 'object'
    delayer.setTimeout 'foo', 1, ->
      done()
    expect(delayer.timeouts.foo).to.be.a 'number'

  it 'should set multiple timeouts with different name', (done) ->
    spy1 = sinon.spy()
    spy2 = sinon.spy()
    delayer.setTimeout 'foo', 1, spy1
    delayer.setTimeout 'bar', 1, spy2
    setTimeout ->
      expect(spy1).was.called()
      expect(spy2).was.called()
      done()
    , 1

  it 'should not set a timeout twice', (done) ->
    spy1 = sinon.spy()
    spy2 = sinon.spy()
    delayer.setTimeout 'foo', 1, spy1
    delayer.setTimeout 'foo', 1, spy2
    setTimeout ->
      expect(spy1).was.notCalled()
      expect(spy2).was.called()
      done()
    , 1

  it 'should remove called timeouts', ->
    expect(delayer.timeouts.foo).to.be undefined

  it 'should allow to clear a timeout', (done) ->
    spy = sinon.spy()
    delayer.setTimeout 'foo', 1, spy
    expect(delayer.clearTimeout).to.be.a 'function'
    delayer.clearTimeout 'foo'
    setTimeout (->
      expect(spy).was.notCalled()
      done()
    ), 1

  it 'should clear all timeouts', (done) ->
    spy1 = sinon.spy()
    spy2 = sinon.spy()
    delayer.setTimeout 'foo', 1, spy1
    delayer.setTimeout 'bar', 1, spy2
    expect(delayer.clearAllTimeouts).to.be.a 'function'
    delayer.clearAllTimeouts()
    setTimeout ->
      expect(spy1).was.notCalled()
      expect(spy2).was.notCalled()
      done()
    , 1

  it 'should allow to set and get an interval', ->
    spy = sinon.spy()
    setIntervalStub = sinon.stub(window, 'setInterval').callsArg(0).returns(12345)
    expect(delayer.setInterval).to.be.a 'function'
    handle = delayer.setInterval 'foo', 50, spy
    expect(handle).to.be 12345
    expect(setIntervalStub).was.called()
    expect(spy).was.called()
    setIntervalStub.restore()

  it 'should create a interval handle store', ->
    setIntervalStub = sinon.stub(window, 'setInterval').returns(12345)
    expect(delayer.intervals).to.be.an 'object'
    delayer.setInterval 'foo', 1, ->
    expect(delayer.intervals.foo).to.be 12345
    setIntervalStub.restore()

  it 'should allow to clear an interval', ->
    spy = sinon.spy()
    clearIntervalStub = sinon.stub window, 'clearInterval'
    handle = delayer.setInterval 'foo', 1, spy
    expect(delayer.clearInterval).to.be.a 'function'
    delayer.clearInterval 'foo'
    expect(clearIntervalStub).was.calledWith handle
    clearIntervalStub.restore()

  it 'should clear all timeouts', ->
    i = 0
    setIntervalStub   = sinon.stub window, 'setInterval', -> ++i
    clearIntervalStub = sinon.stub window, 'clearInterval'
    handle1 = delayer.setInterval 'foo', 1, ->
    handle2 = delayer.setInterval 'bar', 1, ->
    expect(delayer.clearAllIntervals).to.be.a 'function'
    delayer.clearAllIntervals()
    expect(clearIntervalStub.callCount).to.be 2
    expect(clearIntervalStub.getCall(0).args[0]).to.be handle1
    expect(clearIntervalStub.getCall(1).args[0]).to.be handle2
    setIntervalStub.restore()
    clearIntervalStub.restore()

  it 'should clear all timeouts and intervals', ->
    stub1 = sinon.stub delayer, 'clearAllTimeouts'
    stub2 = sinon.stub delayer, 'clearAllIntervals'
    expect(delayer.clearDelayed).to.be.a 'function'
    delayer.clearDelayed()
    expect(stub1).was.called()
    expect(stub2).was.called()
    stub1.restore()
    stub2.restore()
