define () ->
  'use strict'

  # Add functionality to set unique, named timeouts and intervals
  # so they can be cleared afterwards when disposing the object.
  #
  # Mixin this object to add the delayer capability to any object:
  # _(object).extend Delayer
  # Or to a prototype of a class:
  # _(@prototype).extend Delayer
  #

  Delayer =

    setTimeout: (name, time, handler) ->
      @clearTimeout(name)
      @timeouts = @timeouts || {}
      @timeouts[name] = setTimeout handler, time

    clearTimeout: (name) ->
      @timeouts = @timeouts || {}
      clearTimeout @timeouts[name] if @timeouts[name]

    clearAllTimeouts: ->
      @timeouts = @timeouts || {}
      _(@timeouts).chain().keys().each (name) =>
        @clearTimeout name

    setInterval: (name, time, handler) ->
      @clearInterval(name)
      @intervals = @intervals || {}
      @intervals[name] = setInterval handler, time

    clearInterval: (name) ->
      @intervals = @intervals || {}
      clearInterval(@intervals[name]) if @intervals[name]

    clearAllIntervals: ->
      @intervals = @intervals || {}
      _(@intervals).chain().keys().each (name) =>
        @clearInterval name

    clearDelayed: ->
      @clearAllTimeouts()
      @clearAllIntervals()

  # You’re frozen when your heart’s not open
  Object.freeze? Delayer

  Delayer
