mediator = require 'mediator'
utils = require 'chaplin/lib/utils'
Subscriber = require 'chaplin/lib/subscriber'

module.exports = class ApplicationController # Do not inherit from Controller

  # Mixin a Subscriber
  _(ApplicationController.prototype).extend Subscriber

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
    @initialize()

  initialize: ->
    #console.debug 'ApplicationController#initialize'

    # Listen to global events
    @subscribeEvent 'matchRoute', @matchRoute
    @subscribeEvent '!startupController', @startupController

  # Controller management
  # Starting and disposing controllers
  # ----------------------------------

  # Handler for the global matchRoute event
  matchRoute: (route, params) ->
    #console.debug 'ApplicationController#matchRoute'
    @startupController route.controller, route.action, params

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
  startupController: (controllerName, action = 'index', params = {}) ->
    #console.debug 'ApplicationController#startupController', controllerName, action, params

    # Set default flags

    # Whether to update the URL after controller startup
    # Default to true unless explicitly set to false
    if params.changeURL isnt false
      params.changeURL = true

    # Whether to force the controller startup even
    # when current and new controllers and params match
    # Default to false unless explicitly set to true
    if params.forceStartup isnt true
      params.forceStartup = false

    # Check if the desired controller is already active
    isSameController =
      not params.forceStartup and
      @currentControllerName is controllerName and
      @currentAction is action and
      # Deep parameters check is not nice but the simplest way for now
      (not @currentParams or _(params).isEqual(@currentParams))

    # Stop if it’s the same controller/action with the same params
    return if isSameController

    # Fetch the new controller, then go on
    controllerFileName = utils.underscorize(controllerName) + '_controller'
    controller = require "controllers/#{controllerFileName}"
    @controllerLoaded controllerName, action, params, controller

  # Handler for the controller lazy-loading
  controllerLoaded: (controllerName, action, params, ControllerConstructor) ->

    # Shortcuts for the old controller
    currentControllerName = @currentControllerName or null
    currentController     = @currentController     or null

    # Dispose the current controller
    if currentController
      # Notify the rest of the world beforehand
      mediator.publish 'beforeControllerDispose', currentController
      # Passing the params and the new controller name
      currentController.dispose params, controllerName

    # Initialize the new controller
    controller = new ControllerConstructor()

    # Call the initialize method
    # Passing the params and the old controller name
    controller.initialize params, currentControllerName

    # Call the specific controller action
    # Passing the params and the old controller name
    controller[action] params, currentControllerName

    # Save the new controller
    @previousControllerName = currentControllerName
    @currentControllerName = controllerName
    @currentController = controller
    @currentAction = action
    @currentParams = params

    @adjustURL controller, params

    # We're done! Spread the word!
    #console.debug 'publish startupController'
    mediator.publish 'startupController',
      previousControllerName: @previousControllerName
      controller: @currentController
      controllerName: @currentControllerName
      params: @currentParams

  # Change the URL to the new controller using the router
  adjustURL: (controller, params) ->
    if params.path
      # Just use the matched path
      url = params.path

    else if typeof controller.historyURL is 'function'
      # Use controller.historyURL to get the URL
      # If the property is a function, call it
      url = controller.historyURL params

    else if typeof controller.historyURL is 'string'
      # If the property is a string, read it
      url = controller.historyURL

    else
      throw new Error 'ApplicationController#adjustURL: controller for ' +
        "#{@currentControllerName} does not provide a historyURL"

    # Tell the router to actually change the current URL
    if params.changeURL
      mediator.publish '!router:changeURL', url

    # Save the URL
    @url = url

  # Disposal
  # --------

  disposed: false

  dispose: ->
    return if @disposed

    @unsubscribeAllEvents()

    @disposed = true

    # Your're frozen when your heart’s not open
    Object.freeze? this
