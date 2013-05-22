'use strict'

_ = require 'underscore'
Backbone = require 'backbone'
mediator = require 'chaplin/mediator'
Dispatcher = require 'chaplin/dispatcher'
Layout = require 'chaplin/views/layout'
Composer = require 'chaplin/composer'
Router = require 'chaplin/lib/router'
EventBroker = require 'chaplin/lib/event_broker'

# The bootstrapper is the entry point for Chaplin apps.
module.exports = class Application
  # Borrow the `extend` method from a dear friend.
  @extend = Backbone.Model.extend

  # Mixin an `EventBroker` for **publish/subscribe** functionality.
  _.extend @prototype, EventBroker

  # Site-wide title that is mapped to HTML `title` tag.
  title: ''

  # Core Object Instantiation
  # -------------------------

  # The application instantiates three **core modules**:
  dispatcher: null
  layout: null
  router: null
  composer: null

  initialize: (options = {}) ->
    # Initialize core components.
    # ---------------------------

    # Register all routes.
    # You might pass Router/History options as the second parameter.
    # Chaplin enables pushState per default and Backbone uses / as
    # the root per default. You might change that in the options
    # if necessary:
    # @initRouter routes, pushState: false, root: '/subdir/'
    @initRouter options.routes, options

    # Dispatcher listens for routing events and initialises controllers.
    @initDispatcher options

    # Layout listens for click events & delegates internal links to router.
    @initLayout options

    # Composer grants the ability for views and stuff to be persisted.
    @initComposer options

    # Mediator is a global message broker which implements pub / sub pattern.
    @initMediator()

    # Actually start routing.
    @startRouting()

    # Freeze the application instance to prevent further changes.
    Object.freeze? this

  # **Chaplin.Dispatcher** sits between the router and controllers to listen
  # for routing events. When they occur, Chaplin.Dispatcher loads the target
  # controller module and instantiates it before invoking the target action.
  # Any previously active controller is automatically disposed.

  initDispatcher: (options) ->
    @dispatcher = new Dispatcher options

  # **Chaplin.Layout** is the top-level application view. It *does not
  # inherit* from Chaplin.View but borrows some of its functionalities. It
  # is tied to the document dom element and registers application-wide
  # events, such as internal links. And mainly, when a new controller is
  # activated, Chaplin.Layout is responsible for changing the main view to
  # the view of the new controller.

  initLayout: (options = {}) ->
    options.title ?= @title
    @layout = new Layout options

  initComposer: (options = {}) ->
    @composer = new Composer options

  # **Chaplin.mediator** is a singleton that serves as the sole communication
  # channel for all parts of the application. It should be sealed so that its
  # misuse as a kitchen sink is prohibited. If you do want to give modules
  # access to some shared resource, however, add it here before sealing the
  # mediator.

  initMediator: ->
    mediator.seal()

  # **Chaplin.Router** is responsible for observing URL changes. The router
  # is a replacement for Backbone.Router and *does not inherit from it*
  # directly. It's a different implementation with several advantages over
  # the standard router provided by Backbone. The router is typically
  # initialized by passing the function returned by **routes.coffee**.

  initRouter: (routes, options) ->
    # Save the reference for testing introspection only.
    # Modules should communicate with each other via **publish/subscribe**.
    @router = new Router options

    # Register any provided routes.
    routes? @router.match

  startRouting: ->
    # After registering the routes, start **Backbone.history**.
    @router.startHistory()

  # Disposal
  # --------
  disposed: false

  dispose: ->
    # Am I already disposed?
    return if @disposed

    # Check if object is already frozen.
    frozen = Object.isFrozen? this

    properties = ['dispatcher', 'layout', 'router', 'composer']
    for prop in properties when this[prop]?
      this[prop].dispose()
      delete this[prop] unless frozen

    # Nothing is permanent in this wicked world
    @publishEvent 'dispose', this

    # Finished.
    @disposed = true

    # You're frozen when your heart's not open.
    Object.freeze? this
