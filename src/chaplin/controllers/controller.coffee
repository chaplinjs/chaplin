'use strict'

_ = require 'underscore'
Backbone = require 'backbone'
EventBroker = require 'chaplin/lib/event_broker'

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

  initialize: ->
    # Empty per default.

  beforeAction: ->
    # Empty per default.

  # Change document title.
  adjustTitle: (subtitle) ->
    @publishEvent '!adjustTitle', subtitle

  # Composer
  # --------

  # Convenience method to publish the `!composer:compose` event. See the
  # composer for information on parameters, etc.
  compose: (name, second, third) ->
    if arguments.length is 1
      # Retrieve an active composition using the retrieve event.
      item = null
      @publishEvent '!composer:retrieve', name, (composition) ->
        item = composition
      item
    else
      # Compose the arguments using the compose method.
      @publishEvent '!composer:compose', name, second, third

  # Redirection
  # -----------

  # Redirect to URL.
  redirectTo: (url, options) ->
    @redirected = true
    @publishEvent '!router:route', url, options

  # Redirect to named route.
  redirectToRoute: (name, params, options) ->
    @redirected = true
    @publishEvent '!router:routeByName', name, params, options

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
