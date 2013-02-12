'use strict'

_ = require 'underscore'
Backbone = require 'backbone'
EventBroker = require 'chaplin/lib/event_broker'
utils = require 'chaplin/lib/utils'

# Strategist
# ----------
#
# Add functionality to strategise the tracking of requests and disposal of
# bound event handlers.
#
# There are two hooks and 3 strategies. These are a declarative method of
# controlling asynchronous requests. To op-out of any such actions; declare
# strategy to be null or 'null'.
#
# The first hook is on sync; the 3 strategies behave as follows:
#  - 'stack'
#    Allows concurrent requests but keeps track of them in a stack so they
#    may be referenced later to perhaps abort in dispose.
#
#  - 'abort'
#    requests are aborted as requests are made; only allows the last made
#    request.
#
#  - 'null' or null
#    Does nothing.
#
# The second hook is on disposal; the 2 strategies behave as follows:
#  - 'abort'
#    Aborts all pending requests (unless the sync hook was declared to be
#    null in which case this does nothing).
#
#  - 'null', null, or 'stack'
#    Does nothing (allows all pending requests to finish but in the case of
#    'stack', does not execute callbacks)
#
# These strategies may be customized by hook, by request method, by
# both, or at once.
#
# Abort all kinds of requests on both hooks.
# strategy: 'abort'
#
# Abort only on reads but stack everything else.
# strategy:
#   read: 'abort'
#   create: 'stack'
#   update: 'stack'
#   delete: 'stack'
#
# Do nothing; op-out of strategy:
# strategy: null
#
# Abort on subsequent updates but don't abort the update in dispose.
# strategy:
#   update: 'abort'
#   dispose:
#     update: 'abort'

# Wraps a method so that it will observe the disposed propety of an object
# and silently execute (not calling its callback) if it is true.
makeDisposable = (ref, callback) -> ->
  return if ref.disposed
  callback arguments... if callback

# A request wrapper that observes an object that can be disposed. If the
# request is disposed the request is still resolved but no callbacks are fired.
class Disposable

  # Does nothing but stores the request and the observed object reference.
  constructor: (@ref, @request) ->

  # Wrap every parameter which could be a function or an array of
  # functions.
  _wrap: (callbacks...) ->
    result = []
    for callback in callbacks
      result.push if _.isArray callback
        array = []
        array.push makeDisposable @ref, item for item in callback
        array
      else
        makeDisposable @ref, callback
    result

  # Forward the method and wrap the result for the request chaining methods.
  done: -> new Disposable @ref, @request.done (@_wrap arguments...)...
  fail: -> new Disposable @ref, @request.fail (@_wrap arguments...)...
  always: -> new Disposable @ref, @request.always (@_wrap arguments...)...
  then: -> new Disposable @ref, @request.then (@_wrap arguments...)...
  progress: -> new Disposable @ref, @request.progress (@_wrap arguments...)...

  # Forward additional methods.
  abort: -> @request.abort arguments...

module.exports = class Strategist

  # Borrow the static extend method from Backbone
  @extend = Backbone.Model.extend

  # Mixin Backbone events.
  _(@prototype).extend Backbone.Events

  # Hooks that this strategist acts upon.
  hooks: ['sync', 'dispose']

  # Operations that can affect the hook.
  methods: ['read', 'create', 'update', 'delete', 'patch']

  constructor: (options) ->
    # Copy some options to instance properties
    if options
      _(this).extend _.pick options, [
        'strategy'
      ]

    # Invoke initialize.
    @initialize arguments...

  initialize: ->
    # Normalize the strategy object and apply defaults
    return if not @strategy or @strategy is 'null'
    if typeof @strategy is 'string'
      # Strategy can be be declared to be universally abort or stack, etc.
      strategy = @strategy
      @strategy = {}
      for method in @methods
        @strategy[method] = strategy

    # Normalize the handlers object so that inheritance will work correctly.
    # This merges all derived handlers object into the handlers object for the
    # base prototype.
    for version in utils.getAllPropertyVersions this, 'handlers'
      for hook of version
        if @handlers[hook]
          for strategy of version[hook] when not @handlers[hook][strategy]
            @handlers[hook][strategy] = version[hook][strategy]
        else
          @handlers[hook] = version[hook]

    # Expands the strategy object into the full one with both hooks accessible.
    for hook in @hooks
      if @strategy[hook] is null or typeof @strategy[hook] is 'string'
        # This is being declared short-hand like `sync: 'abort'`.
        strategy = @strategy[hook]
        @strategy[hook] = {}
        for method in @methods
          @strategy[hook][method] = strategy
      # If it is still undefined; define it as an empty object
      @strategy[hook] or= {}
      for method in @methods
        @strategy[hook][method] or= @strategy[method] or 'null'

        # Get the strategy; skipping the rest if it was no-op'd
        strategy = @strategy[hook][method]
        continue if strategy is null or strategy is 'null'

        # Initialize the stacks as neccessary
        @requests or= {}
        @handlers.initialize[strategy].call this, method

        # Register handlers to event listeners.
        for suffix in ['', ':before', ':after']
          handler = @handlers["#{hook}#{suffix}"]?[strategy]
          if handler
            @on "#{hook}:#{method}#{suffix}", _.bind handler, this, method

    # Return nothing
    return

  # The various stacks and queues used to facilitate the above.
  requests: null

  # The various handlers to facilitate the above.
  handlers:
    'initialize':
      abort: (method) ->
        # Initialize request store.
        @requests[method] or= null

      stack: (method) ->
        # Initialize request store.
        @requests[method] or= []

    'sync:before':
      abort: (method, options) ->
        # Abort a held request if we have one.
        @requests[method].abort() if @requests[method]

        # Wrap the callbacks so they won't be executed if we get disposed
        # without being aborted.
        if options
          for name in ['success', 'error', 'complete']
            options[name] = makeDisposable this, options[name]

        # Return nothing
        return

      stack: (method, options) ->
        # Wrap the callbacks so they won't be executed if we get disposed.
        if options
          for name in ['success', 'error', 'complete']
            options[name] = makeDisposable this, options[name]

        # Return nothing
        return

    'sync:after':
      abort: (method, request) ->
        # Wrap the request object so that it could be diposed without being
        # aborted.
        request = new Disposable this, request

        # Store and return the request object for later abort.
        @requests[method] = request

      stack: (method, request) ->
        # Keep track of the requests but do nothing beyond that.
        requests = @requests[method]
        request = new Disposable this, request
        requests.push request
        request = request.always =>
          requests = @requests[method]
          requests.splice _(requests).indexOf(request), 1

    'dispose':
      abort: (method) ->
        # Abort all stored requests.
        requests = @requests[method]
        if _(requests).isArray()
          request.abort() for request in requests
        else if requests
          requests.abort()
        delete @requests[method]

  # Disposal
  # --------

  disposed: false

  dispose: ->
    return if @disposed

    # Finished
    @disposed = true

    # Trigger disposal for each method.
    @trigger "dispose:#{method}" for method in @methods

    # Remove all event handlers on this module.
    @off()

    # You’re frozen when your heart’s not open
    Object.freeze? this
