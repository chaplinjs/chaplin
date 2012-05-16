define [
  'jquery',
  'underscore',
  'mediator',
  'chaplin/lib/utils',
  'chaplin/lib/subscriber'
], ($, _, mediator, utils, Subscriber) ->
  'use strict'

  class Layout # This class does not extend View

    # Mixin a Subscriber
    _(@prototype).extend Subscriber

    # The site title used in the document title
    title: ''

    constructor: (options = {}) ->
      ###console.debug 'Layout#constructor', options###

      @title = options.title
      _(options).defaults
        loginClasses: true
        routeLinks: true

      # Listen to global events: Starting and disposing of controllers
      @subscribeEvent 'beforeControllerDispose', @hideOldView
      @subscribeEvent 'startupController', @showNewView
      @subscribeEvent 'startupController', @removeFallbackContent
      @subscribeEvent 'startupController', @adjustTitle

      if options.loginClasses
        # Login and logout
        @subscribeEvent 'loginStatus', @updateLoginClasses
        @updateLoginClasses()

      if options.routeLinks
        @initLinkRouting()

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

    # Fallback content
    # ----------------

    # After the first controller has been started, remove all accessible
    # content so the DOM is less complex and images and video do not lie
    # in the background
    removeFallbackContent: ->
      # Hide fallback content and the loading screens
      $('.accessible-fallback').remove()

      # Remove the handler after the first startupController event
      @unsubscribeEvent 'startupController', @removeFallbackContent

    # Automatic routing of internal links
    # -----------------------------------

    initLinkRouting: ->
      # Handle links
      $(document)
        .on('touchstart mousedown', '.go-to', @goToHandler)
        .on('touchstart mousedown', 'a', @openLink)

    stopLinkRouting: ->
      $(document)
        .off('touchstart mousedown', '.go-to', @goToHandler)
        .off('touchstart mousedown', 'a', @openLink)

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
      ###console.debug 'Layout#dispose'###
      return if @disposed

      @stopLinkRouting()
      @unsubscribeAllEvents()

      delete @title

      @disposed = true

      # Your're frozen when your heart’s not open
      Object.freeze? this
