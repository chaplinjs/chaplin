# Simple finite state machine for synchronization of models/collections
# Three states: unsynced, syncing and synced
# Several transitions between them
# Fires Backbone events on every transition
# (unsynced, syncing, synced; syncStateChange)
# Provides shortcut methods to call handlers when a given state is reached
# (named after the events above)

UNSYNCED = 'unsynced'
SYNCING  = 'syncing'
SYNCED   = 'synced'

STATE_CHANGE = 'syncStateChange'

module.exports = SyncMachine =

  _syncState: UNSYNCED
  _previousSyncState: null

  # Get the current state
  # ---------------------

  syncState: ->
    @_syncState

  isUnsynced: ->
    @_syncState is UNSYNCED

  isSynced: ->
    @_syncState is SYNCED

  isSyncing: ->
    @_syncState is SYNCING

  # Transitions
  # -----------

  unsync: ->
    if @_syncState in [SYNCING, SYNCED]
      @_previousSync = @_syncState
      @_syncState = UNSYNCED
      @trigger @_syncState
      @trigger STATE_CHANGE
    # when UNSYNCED do nothing
    return

  beginSync: ->
    if @_syncState in [UNSYNCED, SYNCED]
      @_previousSync = @_syncState
      @_syncState = SYNCING
      @trigger @_syncState
      @trigger STATE_CHANGE
    # when SYNCING do nothing
    return

  finishSync: ->
    if @_syncState is SYNCING
      @_previousSync = @_syncState
      @_syncState = SYNCED
      @trigger @_syncState
      @trigger STATE_CHANGE
    # when SYNCED, UNSYNCED do nothing
    return

  abortSync: ->
    if @_syncState is SYNCING
      @_syncState = @_previousSync
      @_previousSync = @_syncState
      @trigger @_syncState
      @trigger STATE_CHANGE
    # when UNSYNCED, SYNCED do nothing
    return

# Create shortcut methods to bind a handler to a state change
# -----------------------------------------------------------

for event in [UNSYNCED, SYNCING, SYNCED, STATE_CHANGE]
  do (event) ->
    SyncMachine[event] = (callback, context = @) ->
      @on event, callback, context
      callback.call(context) if @_syncState is event

Object.freeze? SyncMachine

SyncMachine
