'use strict'
Backbone = require 'backbone'
sinon = require 'sinon'
{SyncMachine} = require '../src/chaplin'

describe 'SyncMachine', ->
  machine = null

  beforeEach ->
    machine = {}
    Object.assign machine, Backbone.Events
    Object.assign machine, SyncMachine

  it 'should change its state', ->
    expect(machine.syncState()).to.equal 'unsynced'

    machine.beginSync()
    expect(machine.syncState()).to.equal 'syncing'

    machine.finishSync()
    expect(machine.syncState()).to.equal 'synced'

    machine.unsync()
    expect(machine.syncState()).to.equal 'unsynced'

  it 'should emit sync events', ->
    stateChange = sinon.spy()
    syncing = sinon.spy()
    synced = sinon.spy()

    machine.on 'syncStateChange', stateChange
    machine.on 'syncing', syncing
    machine.on 'synced', synced

    machine.beginSync()
    stateChange.should.have.been.calledOnce
    stateChange.should.have.been.calledWith machine, 'syncing'
    syncing.should.have.been.calledOnce

    machine.finishSync()
    stateChange.should.have.been.calledTwice
    stateChange.should.have.been.calledWith machine, 'synced'
    synced.should.have.been.calledOnce

  it 'should has shortcuts for checking sync state', ->
    expect(machine.isUnsynced()).to.be.true
    expect(machine.isSyncing()).to.be.false
    expect(machine.isSynced()).to.be.false

    machine.beginSync()
    expect(machine.isUnsynced()).to.be.false
    expect(machine.isSyncing()).to.be.true
    expect(machine.isSynced()).to.be.false

    machine.finishSync()
    expect(machine.isUnsynced()).to.be.false
    expect(machine.isSyncing()).to.be.false
    expect(machine.isSynced()).to.be.true

  it 'should be able to abort sync', ->
    machine.beginSync()
    machine.abortSync()
    expect(machine.syncState()).to.equal 'unsynced'

  it 'should has sync callbacks', ->
    syncing = sinon.spy()
    synced = sinon.spy()
    unsynced = sinon.spy()

    machine.syncing syncing
    machine.synced synced
    machine.unsynced unsynced

    machine.beginSync()
    syncing.should.have.been.calledOnce

    machine.finishSync()
    synced.should.have.been.calledOnce

    machine.unsync()
    unsynced.should.have.been.calledTwice # Including initial call.
