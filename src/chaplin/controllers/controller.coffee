'use strict'

_ = require 'underscore'
Backbone = require 'backbone'
EventBroker = require 'chaplin/lib/event_broker'
utils = require 'chaplin/lib/utils'
mediator = require 'chaplin/mediator'

module.exports = class Controller
  # Borrow the static extend method from Backbone.
  @extend = Backbone.Model.extend

  # Mixin Backbone events and EventBroker.
  _.extend @prototype, Backbone.Events
  _.extend @prototype, EventBroker

  view: null

  # Internal flag which stores whether `redirectTo`
  # was called in the current action.
  redirected: false

  constructor: ->
    @initialize arguments...

    # Set up declarative bindings after `initialize` has been called
    # so initialize may create or bind methods.
    @delegateListeners()

  initialize: ->
    # Empty per default.

  beforeAction: ->
    # Empty per default.

  # Change document title.
  adjustTitle: (subtitle) ->
    mediator.execute 'adjustTitle', subtitle

  # Composer
  # --------

  # Convenience method to publish the `!composer:compose` event. See the
  # composer for information on parameters, etc.
  reuse: (name) ->
    method = if arguments.length is 1 then 'retrieve' else 'compose'
    mediator.execute "composer:#{method}", arguments...

  # Deprecated method.
  compose: ->
    throw new Error 'Controller#compose was moved to Controller#reuse'

  # Redirection
  # -----------

  # Redirect to URL.
  redirectTo: (pathDesc, params, options) ->
    @redirected = true
    utils.redirectTo pathDesc, params, options

  # Disposal
  # --------

  disposed: false

  dispose: ->
    return if @disposed

    # Dispose and delete all members which are disposable.
    for own prop, obj of this when obj and typeof obj.dispose is 'function'
      obj.dispose()
      delete this[prop]

    # Unbind handlers of global events.
    @unsubscribeAllEvents()

    # Unbind all referenced handlers.
    @stopListening()

    # Finished.
    @disposed = true

    # You're frozen when your heart’s not open.
    Object.freeze? this
