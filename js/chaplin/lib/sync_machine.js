
define(function() {
  'use strict';
  var STATE_CHANGE, SYNCED, SYNCING, SyncMachine, UNSYNCED, event, _fn, _i, _len, _ref;
  UNSYNCED = 'unsynced';
  SYNCING = 'syncing';
  SYNCED = 'synced';
  STATE_CHANGE = 'syncStateChange';
  SyncMachine = {
    _syncState: UNSYNCED,
    _previousSyncState: null,
    syncState: function() {
      return this._syncState;
    },
    isUnsynced: function() {
      return this._syncState === UNSYNCED;
    },
    isSynced: function() {
      return this._syncState === SYNCED;
    },
    isSyncing: function() {
      return this._syncState === SYNCING;
    },
    unsync: function() {
      var _ref;
      if ((_ref = this._syncState) === SYNCING || _ref === SYNCED) {
        this._previousSync = this._syncState;
        this._syncState = UNSYNCED;
        this.trigger(this._syncState, this, this._syncState);
        this.trigger(STATE_CHANGE, this, this._syncState);
      }
    },
    beginSync: function() {
      var _ref;
      if ((_ref = this._syncState) === UNSYNCED || _ref === SYNCED) {
        this._previousSync = this._syncState;
        this._syncState = SYNCING;
        this.trigger(this._syncState, this, this._syncState);
        this.trigger(STATE_CHANGE, this, this._syncState);
      }
    },
    finishSync: function() {
      if (this._syncState === SYNCING) {
        this._previousSync = this._syncState;
        this._syncState = SYNCED;
        this.trigger(this._syncState, this, this._syncState);
        this.trigger(STATE_CHANGE, this, this._syncState);
      }
    },
    abortSync: function() {
      if (this._syncState === SYNCING) {
        this._syncState = this._previousSync;
        this._previousSync = this._syncState;
        this.trigger(this._syncState, this, this._syncState);
        this.trigger(STATE_CHANGE, this, this._syncState);
      }
    }
  };
  _ref = [UNSYNCED, SYNCING, SYNCED, STATE_CHANGE];
  _fn = function(event) {
    return SyncMachine[event] = function(callback, context) {
      if (context == null) context = this;
      this.on(event, callback, context);
      if (this._syncState === event) return callback.call(context);
    };
  };
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    event = _ref[_i];
    _fn(event);
  }
  if (typeof Object.freeze === "function") Object.freeze(SyncMachine);
  return SyncMachine;
});
