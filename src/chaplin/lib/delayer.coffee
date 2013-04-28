'use strict'

# Delayer
# -------
#
# Add functionality to set unique, named timeouts and intervals
# so they can be cleared afterwards when disposing the object.
# This is especially useful in your custom View class which inherits
# from the standard Chaplin.View.
#
# Mixin this object to add the delayer capability to any object:
# _.extend object, Delayer
#
# Or to a prototype of a class:
# _.extend @prototype, Delayer
#
# In the dispose method, call `clearDelayed` to remove all pending
# timeouts and running intervals:
#
# dispose: ->
#   return if @disposed
#   @clearDelayed()
#   super

Delayer =
  setTimeout: (name, time, handler) ->
    @timeouts ?= {}
    @clearTimeout name
    wrappedHandler = =>
      delete @timeouts[name]
      handler()
    handle = setTimeout wrappedHandler, time
    @timeouts[name] = handle
    handle

  clearTimeout: (name) ->
    return unless @timeouts and @timeouts[name]?
    clearTimeout @timeouts[name]
    delete @timeouts[name]
    return

  clearAllTimeouts: ->
    return unless @timeouts
    for name, handle of @timeouts
      @clearTimeout name
    return

  setInterval: (name, time, handler) ->
    @clearInterval name
    @intervals ?= {}
    handle = setInterval handler, time
    @intervals[name] = handle
    handle

  clearInterval: (name) ->
    return unless @intervals and @intervals[name]
    clearInterval @intervals[name]
    delete @intervals[name]
    return

  clearAllIntervals: ->
    return unless @intervals
    for name, handle of @intervals
      @clearInterval name
    return

  clearDelayed: ->
    @clearAllTimeouts()
    @clearAllIntervals()
    return

# You’re frozen when your heart’s not open
Object.freeze? Delayer

# Return our creation
module.exports = Delayer
