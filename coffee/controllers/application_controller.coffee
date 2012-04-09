define [
  'mediator', 'lib/utils', 'lib/subscriber'
  'controllers/controller',
  'views/application_view',
  'controllers/navigation_controller', 'controllers/sidebar_controller'
], (mediator, utils, Subscriber, Controller, ApplicationView, NavigationController, SidebarController) ->
  'use strict'

  class ApplicationController extends Controller

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

    initialize: ->
      #console.debug 'ApplicationController#initialize'

      # Listen to global events
      @subscribeEvent 'matchRoute', @matchRoute
      @subscribeEvent '!startupController', @startupController

      @initApplicationView()
      @initCommonControllers()

    # Start common controllers and views
    # -----------------------------------

    initApplicationView: ->
      # Save the reference for testing introspection only.
      # Module should communicate with each other via Pub/Sub.
      @view = new ApplicationView()

    initCommonControllers: ->
      # Save the reference for testing introspection only.
      # Module should communicate with each other via Pub/Sub.
      @navigationController = new NavigationController()
      @sidebarController = new SidebarController()

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
      if params.forceStartup isnt true
        params.forceStartup = false

      # Check if the desired controller is already active
      isSameController = not params.forceStartup and
        @currentControllerName is controllerName and
        @currentAction is action and
        # Deep parameters check is not nice but the simplest way for now
        (not @currentParams or _(params).isEqual(@currentParams))

      # Stop if it’s the same controller/action with the same params
      return if isSameController

      # Fetch the new controller, then go on
      controllerFileName = utils.underscorize(controllerName) + '_controller'
      handler = _(@controllerLoaded).bind(this, controllerName, action, params)
      require ['controllers/' + controllerFileName], handler

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
      # Ask the the controller for the URL
      if typeof controller.historyURL is 'function'
        # If the property is a function, call it
        url = controller.historyURL params
      else if typeof controller.historyURL is 'string'
        url = controller.historyURL
      else
        throw new Error "ApplicationController#adjustURL: controller for
 #{@currentControllerName} does not provide a historyURL"

      # Pass to the router to actually change the current URL
      if params.changeURL
        mediator.router.changeURL url

      # Save the URL
      @url = url
