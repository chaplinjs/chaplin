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
      @subscribeEvent '!startupController', @startupController

    # Controller management
    # Starting and disposing controllers
    # ----------------------------------

    # Handler for the global matchRoute event
    matchRoute: (route, params, options) ->
      @startupController route.controller, route.action, params, options

    # Handler for the global !startupController event
    #
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

      if _.isObject(controller.before)
        # Call the matching before filters
        @executeFilters [controller, arguments...]...
      else
        # Restore execution onto the action
        @executeAction [controller, arguments...]...

    # Handler for the controller lazy-loading
    executeAction: (controller, controllerName, action, params, options) ->
      # Shortcuts for the old controller
      currentControllerName = @currentControllerName or null
      currentController     = @currentController     or null

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
      @previousControllerName = currentControllerName
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

    # Before action filters with chained execution
    executeFilters: (controller, controllerName, action, params, options) ->
      filters  = []
      previous = null
      args = arguments

      # Iterate through the before filters object in search for a matching
      # name with the arguments' action name
      for filterName, filterFn of controller.before
        regexp = null
        if filterName.indexOf('*') isnt -1
          regexp = new RegExp("^#{filterName.replace('*','(.*)')}$")

        if filterName is action or regexp?.test action
          method = controller.before[filterName]
          method = controller[method] unless _.isFunction method
          unless method
            throw new Error('Filter method for "' + filterName + '" does not exist.')
          filters.unshift method

      # Save returned value and also immediately return in case the value is false
      next = (method) =>
        # Stop if the action triggered a redirect
        return if controller.redirected
        # End of chain, restore execution onto the action
        unless method?
          return @executeAction args...

        # Detecting a CommonJS promise object in order to use pipelining below,
        # otherwise execute next method directly
        unless _.isObject(previous) and _.has(previous, 'then')
          previous = method params, previous
          next filters.shift()
        # Chaining defer objects...
        else
          callback = _.bind(method, controller, params)
          previous.done (data) ->
            previous = callback data
            next filters.shift()

      # Start filter execution chain
      next filters.shift()

    # Change the URL to the new controller using the router
    adjustURL: (controller, params, options) ->
      if typeof options.path is 'string'
        # Just use the matched path
        url = options.path

      else if typeof controller.historyURL is 'function'
        # Use controller.historyURL to get the URL
        # If the property is a function, call it
        url = controller.historyURL params

      else if typeof controller.historyURL is 'string'
        # If the property is a string, read it
        url = controller.historyURL

      else
        throw new Error 'Dispatcher#adjustURL: controller for ' +
          "#{@currentControllerName} does not provide a historyURL"

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
