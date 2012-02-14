define ['mediator', 'lib/utils'], (mediator, utils) ->

  'use strict'

  class ApplicationView # Do not inherit from View

    # Set your application name here so
    # the document title is set properly to
    # “Site title – Controller title” (see adjustTitle)
    siteTitle = 'Architecture Example'

    previousController: null

    # The current controller, its name, main view and parameters
    currentControllerName: null
    currentController: null
    currentAction: null
    currentView: null
    currentParams: null

    # The current URL
    url: null

    constructor: ->
      @logout() unless mediator.user

      # Listen to global events
      mediator.subscribe '!startupController', @startupController
      mediator.subscribe 'login', @login
      mediator.subscribe 'logout', @logout
      mediator.subscribe 'startupController', @removeFallbackContent

      @addGlobalHandlers()

    # Handlers for user login / logout

    # Handler for the global login event

    login: (user) =>
      #console.debug 'ApplicationView#login', user

      $(document.body)
        # Switch login state classes
        .removeClass('logged-out')
        .addClass('logged-in')

    # Handler for the global logout event

    logout: =>
      #console.debug 'ApplicationView#logout'
      $(document.body)
        # Switch login state classes
        .removeClass('logged-in')
        .addClass('logged-out')


    # Controller management - starting controllers, showing and hiding views


    # Handler for the global !startupController event
    #
    # The standard flow is:
    #
    #   1. Test if it’s a new controller/action with new params
    #   1. Hide the old view
    #   2. Destroy the old controller
    #   3. Instantiate and startup up the new controller
    #   4. Show the new view

    startupController: (controllerName, action = 'index', params = {}) =>
      #console.debug 'ApplicationView#startupController\n\t' +
      #  "#{@currentControllerName}##{@currentAction} > #{controllerName}##{action} params #{params}"

      # Set default flags

      # Whether to update the URL after controller startup
      params.navigate = true unless params.navigate is false

      # Whether to force the controller startup even
      # when current and new controllers and params match
      params.forceStartup = false unless params.forceStartup is true

      # Check if the desired controller is already active
      sameController = not params.forceStartup and
        @currentControllerName is controllerName and
        @currentAction is action and
        # Deep parameters check is not nice but the simplest way for now
        (not @currentParams or _(params).isEqual(@currentParams))

      #console.debug 'ApplicationView#startupController sameController?', sameController

      # Stop if it’s the same controller/action with the same params
      if sameController
        #console.debug "ApplicationView#startupController: #{controllerName}##{action} already active with same parameters"
        return

      # Fetch the new controller, then go on
      controllerFileName = utils.underscorize(controllerName) + '_controller'
      require ['controllers/' + controllerFileName],
        _(@controllerLoaded).bind(@, controllerName, action, params)

    # Handler for the controller lazy-loading

    controllerLoaded: (controllerName, action, params, ControllerConstructor) ->
      #console.debug 'ApplicationView#controllerLoaded', controllerName, action, params, ControllerConstructor

      # Shortcuts for the old controller
      currentControllerName = @currentControllerName or null
      currentController     = @currentController     or null
      currentView           = @currentController.view if @currentController

      # Jump to the top of the page
      scrollTo 0, 0

      # Hide the container element of the current view
      if currentView and currentView.$container
        currentView.$container.css 'display', 'none'

      # Dispose the current controller
      if currentController
        unless typeof currentController.dispose is 'function'
          throw new Error "ApplicationView#controllerLoaded: dispose method not found on #{currentControllerName} controller"
        # Passing the params and the new controller name
        currentController.dispose params, controllerName

      # Initialize the new controller
      controller = new ControllerConstructor()

      # Call the startup method
      unless typeof controller.startup is 'function'
        throw new Error "ApplicationView#controllerLoaded: startup method not found on #{controllerName} controller"
      # Passing the params and the old controller name
      controller.startup params, currentControllerName

      # Call the specific controller action
      unless typeof controller[action] is 'function'
        throw new Error "ApplicationView#controllerLoaded: action #{action} not found on #{controllerName} controller"
      controller[action] params, currentControllerName

      # Show the container element of the new view
      view = controller.view
      if view and view.$container
        view.$container.css display: 'block', opacity: 1

      # Save the new controller
      @previousController    = currentControllerName
      @currentControllerName = controllerName
      @currentController     = controller
      @currentView           = view
      @currentParams         = params

      # Change the URL to the new controller
      @adjustURL()

      # Change the document title to match the current controller
      @adjustTitle()

      # We're done! Publish a global startupController event with these parameters:
      # - name of the new controller
      # - params for the new controllre
      # - name of the old controller
      #console.debug 'ApplicationView#startupController: publish startupController', @currentControllerName, @currentParams, @previousController
      mediator.publish 'startupController', @currentControllerName, @currentParams, @previousController

    # Change the URL to the new controller using the Backbone Router

    adjustURL: ->
      # Shortcuts
      controller = @currentController
      params     = @currentParams

      #console.debug 'ApplicationView#adjustURL', controller, params

      if typeof controller.historyURL is 'function'
        # If the property is a function, call it
        historyURL = controller.historyURL params

      else if typeof controller.historyURL is 'string'
        historyURL = controller.historyURL

      else
        throw new Error "ApplicationView#adjustURL: controller for #{controllerName} does not provide a historyURL"

      # Pass to the router to actually change the current URL
      if params.navigate
        mediator.router.navigate historyURL

      # Save the URL
      @url = "/#{historyURL}"

    # Change the document title. Get the title from the title property
    # of the params or of the current controller

    adjustTitle: ->
      # You might change this if you want the opposite order of
      # the controller and site titles
      title = siteTitle
      subtitle = @currentParams.title or @currentController.title
      title += " \u2013 #{subtitle}" if subtitle
      # Internet Explorer < 9 workaround
      setTimeout (-> document.title = title), 50


    # After the first controller has been started, remove all accessible content
    # so the DOM is less complex and images and video do not lie in the background

    removeFallbackContent: =>
      # Hide the accessible fallback and the loading screen
      $('#startup-loading, .accessible-fallback').remove()

      # Remove the handler after the first startupController event
      mediator.unsubscribe 'startupController', @removeFallbackContent


    # Global event handlers

    addGlobalHandlers: ->
      # Handle links
      $(document)
        .delegate('#logout-button', 'click', @logoutButtonClick)
        .delegate('.go-to',         'click', @goToHandler)
        .delegate('a',              'click', @openLink)

    # Handle all clicks on A elements and try to route them internally

    openLink: (e) =>
      #console.debug 'AppView#openLink'
      el = e.currentTarget

      # Handle empty href
      hrefAttr = el.getAttribute 'href'
      #console.debug '\threfAttr »' + hrefAttr + '«'
      return if hrefAttr is '' or /^#/.test(hrefAttr)

      # Is it an external link?
      href = el.href
      hostname = el.hostname
      #console.debug '\thref »' + href + '«'
      #console.debug '\thostname »' + hostname + '«'
      return unless href and hostname

      currentHostname = location.hostname.replace('.', '\\.')
      hostnameRegExp = new RegExp("#{currentHostname}$", 'i')
      external = not hostnameRegExp.test(hostname)
      #console.debug '\texternal?', external
      if external
        # Open external links normally
        return

      @openInternalLink e

    # Try to route a click on a link internally

    openInternalLink: (e) ->
      #console.debug 'AppView#openInternalLink'
      e.preventDefault()
      el = e.currentTarget

      path = el.pathname
      #console.debug '\tpath »' + path + '«'
      return unless path

      # Pass to the router. Returns true if the URL could be routed.
      result = mediator.router.follow path, navigate: true
      #console.debug '\tfollow result', result

      e.preventDefault() if result

    # Not only A elements might act as internal links,
    # every element might have:
    # class="go-to" data-href="/something"

    goToHandler: (e) ->
      el = e.currentTarget
      #console.debug 'AppView#goToHandler', el, e.nodeName, $(el).data('href')

      # Do not handle A elements
      return if e.nodeName is 'A'

      path = $(el).data('href')
      return unless path

      # Call the
      result = mediator.router.follow path, navigate: true
      #console.debug '\tfollow result', result

      e.preventDefault() if result

    # Handle clicks on the logout button

    logoutButtonClick: (e) ->
      e.preventDefault()

      # Publish a global !logout event
      mediator.publish '!logout'
