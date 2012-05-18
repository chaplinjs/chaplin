define [
  'jquery',
  'underscore',
  'chaplin/mediator',
  'chaplin/lib/utils',
  'chaplin/lib/subscriber'
], ($, _, mediator, utils, Subscriber) ->
  'use strict'

  class Layout # This class does not extend View

    # Mixin a Subscriber
    _(@prototype).extend Subscriber

    # The site title used in the document title
    # This should be set in your app-specific Application class
    # and passed as an option
    title: ''

    constructor: ->
      @initialize arguments...

    initialize: (options = {}) ->
      @title = options.title
      _(options).defaults
        loginClasses: true
        routeLinks: true

      # Listen to global events: Starting and disposing of controllers
      # Showing and hiding the main views
      @subscribeEvent 'beforeControllerDispose', @hideOldView
      @subscribeEvent 'startupController', @showNewView
      # Adjust the document titel to reflect the current controller
      @subscribeEvent 'startupController', @adjustTitle

      # set app wide event handlers
      @delegateEvents()

      if options.loginClasses
        @subscribeEvent 'loginStatus', @updateLoginClasses
        @updateLoginClasses()

      if options.routeLinks
        @initLinkRouting()



    # Register DOM events based on the events hash
    # --------------------------------------------

    toggleEvents: (direction) ->
      return if !@events || _.isEmpty(@events)
      $document = $(document)

      for key, handler of @events
        match = key.match(/^(\S+)\s*(.*)$/);
        eventName = match[1]
        selector = match[2]
        handler = this[handler] if !_.isFunction(handler)
        handler = _.bind(handler, this)

        if direction == 'on'
          $document.on( eventName, selector, handler )
        else if direction == 'off'
          $document.off( eventName, selector, handler )

    delegateEvents: ->
      @undelegateEvents
      @toggleEvents 'on'

    undelegateEvents: ->
      @toggleEvents 'off'


    # Controller startup and disposal
    # -------------------------------

    # Handler for the global beforeControllerDispose event
    hideOldView: (controller) ->
      # Jump to the top of the page
      scrollTo 0, 0

      # Hide the current view
      view = controller.view
      if view
        view.$el.css 'display', 'none'

    # Handler for the global startupController event
    # Show the new view
    showNewView: (context) ->
      view = context.controller.view
      if view
        view.$el.css display: 'block', opacity: 1, visibility: 'visible'

    # Handler for the global startupController event
    # Change the document title to match the new controller
    # Get the title from the title property of the current controller
    adjustTitle: (context) ->
      title = @title
      subtitle = context.controller.title
      title = "#{subtitle} \u2013 #{title}" if subtitle
      # Internet Explorer < 9 workaround
      setTimeout (-> document.title = title), 50

    # Logged-in / logged-out classes for the body element
    # ---------------------------------------------------

    updateLoginClasses: (loggedIn) ->
      $(document.body)
        .toggleClass('logged-out', not loggedIn)
        .toggleClass('logged-in', loggedIn)

    # Automatic routing of internal links
    # -----------------------------------

    initLinkRouting: ->
      # Handle links
      $(document)
        .on('click', '.go-to', @goToHandler)
        .on('click', 'a', @openLink)

    stopLinkRouting: ->
      $(document)
        .off('click', '.go-to', @goToHandler)
        .off('click', 'a', @openLink)

    # Handle all clicks on A elements and try to route them internally
    openLink: (event) =>
      return if utils.modifierKeyPressed(event)

      el = event.currentTarget
      href = el.getAttribute 'href'
      # Ignore empty paths even if it is a valid relative URL
      # Ignore links to fragment identifiers
      return if href is null or
        href is '' or
        href.charAt(0) is '#' or
        $(el).hasClass('noscript')

      # Is it an external link?
      currentHostname = location.hostname.replace('.', '\\.')
      external = not ///#{currentHostname}$///i.test(el.hostname)
      if external
        # Open external links normally
        # You might want to enforce opening in a new tab here:
        #event.preventDefault()
        #window.open el.href
        return

      # Try to route the link internally

      # Get the path with query string
      path = el.pathname + el.search
      # Append a leading slash if necessary (Internet Explorer 8)
      path = "/#{path}" if path.charAt(0) isnt '/'

      # Pass to the router, try to route internally
      mediator.publish '!router:route', path, (routed) ->
        # Prevent default handling if the URL could be routed
        event.preventDefault() if routed
        # Otherwise navigate to the URL normally

    # Not only A elements might act as internal links,
    # every element might have:
    # class="go-to" data-href="/something"
    goToHandler: (event) ->
      el = event.currentTarget

      # Do not handle A elements
      return if event.nodeName is 'A'

      path = $(el).data('href')
      # Ignore empty path even if it is a valid relative URL
      return unless path

      # Pass to the router, try to route internally
      mediator.publish '!router:route', path, (routed) ->
        if routed
          # Prevent default handling if the URL could be routed
          event.preventDefault()
        else
          # Navigate to the URL normally
          location.href = path

    # Disposal
    # --------

    disposed: false

    dispose: ->
      return if @disposed

      @stopLinkRouting()
      @unsubscribeAllEvents()

      delete @title

      @disposed = true

      # Your're frozen when your heart’s not open
      Object.freeze? this
