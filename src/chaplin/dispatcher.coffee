'use strict'

_ = require 'underscore'
Backbone = require 'backbone'
utils = require 'chaplin/lib/utils'
EventBroker = require 'chaplin/lib/event_broker'

module.exports = class Dispatcher
  # Borrow the static extend method from Backbone.
  @extend = Backbone.Model.extend

  # Mixin an EventBroker.
  _(@prototype).extend EventBroker

  # The previous route information.
  # This object contains the controller name, action, path, and name (if any).
  previousRoute: null

  # The current controller, route information, and parameters.
  # The current route object contains the same information as previous.
  currentController: null
  currentRoute: null
  currentParams: null

  constructor: ->
    @initialize arguments...

  initialize: (options = {}) ->
    # Merge the options.
    @settings = _(options).defaults
      controllerPath: 'controllers/'
      controllerSuffix: '_controller'

    # Listen to global events.
    @subscribeEvent 'router:match', @dispatch

  # Controller management.
  # Starting and disposing controllers.
  # ----------------------------------

  # The standard flow is:
  #
  #   1. Test if it’s a new controller/action with new params
  #   1. Hide the previous view
  #   2. Dispose the previous controller
  #   3. Instantiate the new controller, call the controller action
  #   4. Show the new view
  #
  dispatch: (route, params, options) ->
    # Clone params and options so the original objects remain untouched.
    params = if params then _.clone(params) else {}
    options = if options then _.clone(options) else {}

    # Whether to update the URL after controller startup.
    # Default to true unless explicitly set to false.
    options.changeURL = true unless options.changeURL is false

    # Whether to force the controller startup even
    # if current and new controllers and params match
    # Default to false unless explicitly set to true.
    options.forceStartup = false unless options.forceStartup is true

    # Stop if the desired controller/action is already active
    # with the same params.
    return if not options.forceStartup and
      @currentRoute?.controller is route.controller and
      @currentRoute?.action is route.action and
      _.isEqual @currentParams, params

    # Fetch the new controller, then go on.
    @loadController route.controller, (Controller) =>
      @controllerLoaded route, params, options, Controller

  # Load the constructor for a given controller name.
  # The default implementation uses require() from a AMD module loader
  # like RequireJS to fetch the constructor.
  loadController: (name, handler) ->
    fileName = utils.underscorize(name) + @settings.controllerSuffix
    moduleName = @settings.controllerPath + fileName
    if define?.amd
      require [moduleName], handler
    else
      handler require moduleName

  # Handler for the controller lazy-loading.
  controllerLoaded: (route, params, options, Controller) ->
    # Store the current route as the previous route.
    @previousRoute = @currentRoute

    # Setup the current route object.
    @currentRoute = _.extend {}, route, previous: utils.beget @previousRoute

    # Initialize the new controller.
    controller = new Controller params, @currentRoute, options

    # Execute before actions if necessary.
    methodName = if controller.beforeAction
      'executeBeforeActions'
    else
      'executeAction'
    this[methodName](controller, @currentRoute, params, options)

  executeAction: (controller, route, params, options) ->
    # Dispose the previous controller.
    if @currentController
      # Notify the rest of the world beforehand.
      @publishEvent 'beforeControllerDispose', @currentController

      # Passing new parameters that the action method will receive.
      @currentController.dispose params, route, options

    # Call the controller action with params and options.
    controller[route.action] params, route, options

    # Stop if the action triggered a redirect.
    return if controller.redirected

    # Save the new controller and its parameters.
    @currentController = controller
    @currentParams = params

    # Adjust the URL.
    @adjustURL params, options

    # We're done! Spread the word!
    @publishEvent 'dispatcher:dispatch', @currentController,
      params, route, options

  # Before actions with chained execution.
  executeBeforeActions: (controller, route, params, options) ->
    beforeActions = []

    # Before actions can be extended by subclasses, so we need to check the
    # whole prototype chain for matching before actions. Before actions in
    # parent classes are executed before actions in child classes.
    for actions in utils.getAllPropertyVersions controller, 'beforeAction'

      # Iterate over the before actions in search for a matching
      # name with the arguments’ action name.
      for name, action of actions

        # Do not add this object more than once.
        if name is route.action or RegExp("^#{name}$").test route.action

          if typeof action is 'string'
            action = controller[action]

          unless typeof action is 'function'
            throw new Error 'Controller#executeBeforeActions: ' +
              "#{action} is not a valid action method for #{name}."

          # Save the before action.
          beforeActions.push action

    # Save returned value and also immediately return in case the value is false.
    next = (method, previous = null) =>
      # Stop if the action triggered a redirect.
      return if controller.redirected

      # End of chain, finally start the action.
      unless method
        @executeAction controller, route, params, options
        return

      # Execute the next before action.
      previous = method.call controller, params, route, options, previous

      # Detect a CommonJS promise in order to use pipelining below,
      # otherwise execute next method directly.
      if previous and typeof previous.then is 'function'
        previous.then (data) =>
          # Execute as long as the currentController is
          # the callee for this promise.
          if not @currentController or controller is @currentController
            next beforeActions.shift(), data
      else
        next beforeActions.shift(), previous

    # Start beforeAction execution chain.
    next beforeActions.shift()

  # Change the URL to the new controller using the router.
  adjustURL: (params, options) ->
    return unless options.path?

    url = options.path +
      if options.queryString then "?#{options.queryString}" else ""

    # Tell the router to actually change the current URL.
    @publishEvent '!router:changeURL', url, options if options.changeURL

    # Save the URL.
    @url = url

  # Disposal
  # --------

  disposed: false

  dispose: ->
    return if @disposed

    @unsubscribeAllEvents()

    @disposed = true

    # You’re frozen when your heart’s not open.
    Object.freeze? this
