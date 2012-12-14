define [
  'underscore'
  'backbone'
  'chaplin/lib/utils'
  'chaplin/lib/event_broker'
], (_, Backbone, utils, EventBroker) ->
  'use strict'

  class Dispatcher

    # Borrow the static extend method from Backbone
    @extend = Backbone.Model.extend

    # Mixin an EventBroker
    _(@prototype).extend EventBroker

    # The previous controller name
    previousControllerName: null

    # The current controller, its name, main view and parameters
    currentControllerName: null
    currentController: null
    currentAction: null
    currentParams: null

    # The current URL
    url: null

    constructor: ->
      @initialize arguments...

    initialize: (options = {}) ->
      # Merge the options
      @settings = _(options).defaults
        controllerPath: 'controllers/'
        controllerSuffix: '_controller'

      # Listen to global events
      @subscribeEvent 'matchRoute', @matchRoute

    # Controller management
    # Starting and disposing controllers
    # ----------------------------------

    # Handler for the global matchRoute event
    matchRoute: (route, params, options) ->
      @startupController route.controller, route.action, params, options

    # The standard flow is:
    #
    #   1. Test if it’s a new controller/action with new params
    #   1. Hide the old view
    #   2. Dispose the old controller
    #   3. Instantiate the new controller, call the controller action
    #   4. Show the new view
    #
    startupController: (controllerName, action = 'index', params = {},
                        options = {}) ->
      # Set default flags

      # Whether to update the URL after controller startup
      # Default to true unless explicitly set to false
      if options.changeURL isnt false
        options.changeURL = true

      # Whether to force the controller startup even
      # when current and new controllers and params match
      # Default to false unless explicitly set to true
      if options.forceStartup isnt true
        options.forceStartup = false

      # Check if the desired controller is already active
      isSameController =
        not options.forceStartup and
        @currentControllerName is controllerName and
        @currentAction is action and
        # Deep parameters check is not nice but the simplest way for now
        (not @currentParams or _(params).isEqual(@currentParams))

      # Stop if it’s the same controller/action with the same params
      return if isSameController

      # Fetch the new controller, then go on
      handler = _(@controllerLoaded).bind(
        this, controllerName, action, params, options)

      @loadController controllerName, handler

    # Load the constructor for a given controller name.
    # The default implementation uses require() from a AMD module loader
    # like RequireJS to fetch the constructor.
    loadController: (controllerName, handler) ->
      controllerFileName = utils.underscorize(controllerName) + @settings.controllerSuffix
      path = @settings.controllerPath + controllerFileName
      if define?.amd
        require [path], handler
      else
        handler require path

    controllerLoaded: (controllerName, action, params, options, ControllerConstructor) ->
      # Shortcuts for the old controller
      currentControllerName = @currentControllerName or null
      # Initialize the new controller
      # Passing the params and the old controller name
      controller = new ControllerConstructor params, currentControllerName

      method = if controller.beforeAction
        'executeBeforeActionChain'
      else
        'executeAction'

      this[method](controller, controllerName, action, params, options)

    # Handler for the controller lazy-loading
    executeAction: (controller, controllerName, action, params, options) ->
      # Shortcuts for the old controller
      currentControllerName   = @currentControllerName or null
      currentController       = @currentController     or null

      @previousControllerName = currentControllerName

      # Dispose the current controller
      if currentController
        # Notify the rest of the world beforehand
        @publishEvent 'beforeControllerDispose', currentController
        # Passing the params and the new controller name
        currentController.dispose params, controllerName

      # Call the specific controller action
      # Passing the params and the old controller name
      controller[action] params, currentControllerName

      # Stop if the action triggered a redirect
      return if controller.redirected

      # Save the new controller
      @currentControllerName = controllerName
      @currentController = controller
      @currentAction = action
      @currentParams = params

      # Adjust the URL; pass in both params and options
      @adjustURL controller, params, options

      # We're done! Spread the word!
      @publishEvent 'startupController',
        previousControllerName: @previousControllerName
        controller: @currentController
        controllerName: @currentControllerName
        params: @currentParams

    # Before actions with chained execution
    executeBeforeActionChain: (controller, controllerName, action, params) ->
      beforeActions  = []
      args = arguments

      # Before actions can be extended by subclasses, so we need to check the
      # whole prototype chain for matching before actions. Before actions in
      # parent classes are executed before actions in child classes.

      prototypeChain = utils.getPrototypeChain controller
      for prototype in prototypeChain.reverse()

        # Iterate over the before actions in search for a matching
        # name with the arguments’ action name
        for name, beforeAction of prototype.beforeAction
          # Do not add this object more than once
          continue if _.indexOf(beforeActions, beforeAction) >= 0
          if name is action or RegExp("^#{name}$").test(action)
            if typeof beforeAction is 'string'
              beforeAction = controller[beforeAction]
            if typeof beforeAction isnt 'function'
              throw new Error 'Controller#executeBeforeActionChain: ' +
                "#{beforeAction} is not a valid beforeAction method for #{name}."
            # Save the before action
            beforeActions.push beforeAction

      # Save returned value and also immediately return in case the value is false
      next = (method, previous = null) =>
        # Stop if the action triggered a redirect
        if controller.redirected
          # Adjust the URL; pass in params
          return @adjustURL controller, params, {}

        # End of chain, finally start the action
        unless method
          return @executeAction args...

        previous = method.call controller, params, previous

        # Detect a CommonJS promise  in order to use pipelining below,
        # otherwise execute next method directly
        if previous and typeof previous.then is 'function'
          previous.then (data) ->
            next beforeActions.shift(), data
        else
          next beforeActions.shift(), previous

      # Start beforeAction execution chain
      next beforeActions.shift()

    # Change the URL to the new controller using the router
    adjustURL: (controller, params, options) ->
      if typeof options.path is 'string'
        # Just use the matched path
        url = options.path

      # Tell the router to actually change the current URL
      @publishEvent '!router:changeURL', url, options if options.changeURL

      # Save the URL
      @url = url

    # Disposal
    # --------

    disposed: false

    dispose: ->
      return if @disposed

      @unsubscribeAllEvents()

      @disposed = true

      # You’re frozen when your heart’s not open
      Object.freeze? this
