define [
  'backbone'
  'underscore'
  'chaplin/lib/sync_machine'
], (Backbone, _, SyncMachine) ->
  'use strict'

  describe 'SyncMachine', ->
    machine = null
    beforeEach ->
      machine = {}
      _(machine).extend Backbone.Events
      _(machine).extend SyncMachine

    it 'should change its state', ->
      expect(machine.syncState()).to.be 'unsynced'

      machine.beginSync()
      expect(machine.syncState()).to.be 'syncing'

      machine.finishSync()
      expect(machine.syncState()).to.be 'synced'

      machine.unsync()
      expect(machine.syncState()).to.be 'unsynced'

    it 'should emit sync events', ->
      stateChange = sinon.spy()
      syncing = sinon.spy()
      synced = sinon.spy()
      unsynced = sinon.spy()

      machine.on 'syncStateChange', stateChange
      machine.on 'syncing', syncing
      machine.on 'synced', synced
      machine.on 'unsynced', unsynced

      machine.beginSync()
      expect(stateChange).was.calledOnce()
      expect(stateChange).was.calledWith 'syncing'
      expect(syncing).was.calledOnce()

      machine.finishSync()
      expect(stateChange).was.calledTwice()
      expect(stateChange).was.calledWith 'synced'
      expect(synced).was.calledOnce()

    it 'should has shortcuts for checking sync state', ->
      expect(machine.isUnsynced()).to.be true
      expect(machine.isSyncing()).to.be false
      expect(machine.isSynced()).to.be false

      machine.beginSync()
      expect(machine.isUnsynced()).to.be false
      expect(machine.isSyncing()).to.be true
      expect(machine.isSynced()).to.be false

      machine.finishSync()
      expect(machine.isUnsynced()).to.be false
      expect(machine.isSyncing()).to.be false
      expect(machine.isSynced()).to.be true

    it 'should be able to abort sync', ->
      machine.beginSync()
      machine.abortSync()
      expect(machine.syncState()).to.be 'unsynced'

    it 'should has sync callbacks', ->
      syncing = sinon.spy()
      synced = sinon.spy()
      unsynced = sinon.spy()

      machine.whenSyncing syncing
      machine.whenSynced synced
      machine.whenUnsynced unsynced

      machine.beginSync()
      expect(syncing).was.calledOnce()

      machine.finishSync()
      expect(synced).was.calledOnce()

      machine.unsync()
      expect(unsynced).was.calledTwice()  # Including initial call.
