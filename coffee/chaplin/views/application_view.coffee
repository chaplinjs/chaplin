define [
  'mediator', 'chaplin/lib/utils', 'chaplin/lib/subscriber'
], (mediator, utils, Subscriber) ->
  'use strict'

  class ApplicationView # This class does not extend View

    # Mixin a Subscriber
    _(ApplicationView.prototype).extend Subscriber

    # The site title used in the document title
    title: ''

    constructor: (options = {}) ->
      #console.debug 'ApplicationView#constructor', options

      @title = options.title

      # Listen to global events

      # Starting and disposing of controllers
      @subscribeEvent 'beforeControllerDispose', @hideOldView
      @subscribeEvent 'startupController', @showNewView
      @subscribeEvent 'startupController', @removeFallbackContent
      @subscribeEvent 'startupController', @adjustTitle

      # Login and logout
      @subscribeEvent 'loginStatus', @updateBodyClasses

      @updateBodyClasses()
      @addDOMHandlers()

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
      #console.debug 'ApplicationView#adjustTitle', context
      title = @title
      subtitle = context.controller.title
      title = "#{subtitle} \u2013 #{title}" if subtitle
      # Internet Explorer < 9 workaround
      setTimeout (-> document.title = title), 50

    # Logged-in / logged-out classes for the body element
    # ---------------------------------------------------

    updateBodyClasses: (loggedIn) ->
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

    # DOM Event handling
    # ------------------

    addDOMHandlers: ->
      # Handle links
      $(document)
        .delegate('.go-to', 'click', @goToHandler)
        .delegate('a', 'click', @openLink)

    # Handle all clicks on A elements and try to route them internally
    openLink: (event) =>
      #console.debug 'ApplicationView#openLink'
      return if utils.modifierKeyPressed(event)

      el = event.currentTarget
      href = el.getAttribute 'href'
      # Ignore empty path even if it is a valid relative URL
      return if href is '' or href.charAt(0) is '#'

      # Is it an external link?
      currentHostname = location.hostname.replace('.', '\\.')
      hostnameRegExp = ///#{currentHostname}$///i
      external = not hostnameRegExp.test(el.hostname)
      if external
        #console.debug 'ApplicationView#openLink: external link', el.hostname
        # Open external links normally
        # You might want to enforce opening in a new tab here:
        #event.preventDefault()
        #window.open el.href
        return

      @openInternalLink event

    # Try to route a click on a link internally
    openInternalLink: (event) ->
      #console.debug 'ApplicationView#openInternalLink'
      return if utils.modifierKeyPressed(event)

      el = event.currentTarget
      path = el.pathname
      return unless path

      # Pass to the router, try to route internally
      mediator.publish '!router:route', path, (routed) ->
        #console.debug 'ApplicationView#openInternalLink routed:', routed
        # Prevent default handling if the URL could be routed
        event.preventDefault() if routed
        # Otherwise navigate to the URL normally

    # Not only A elements might act as internal links,
    # every element might have:
    # class="go-to" data-href="/something"
    goToHandler: (event) ->
      #console.debug 'ApplicationView#goToHandler'
      el = event.currentTarget

      # Do not handle A elements
      return if event.nodeName is 'A'

      path = $(el).data('href')
      # Ignore empty path even if it is a valid relative URL
      return unless path

      # Pass to the router, try to route internally
      mediator.publish '!router:route', path, (routed) ->
        #console.debug 'ApplicationView#goToHandler routed:', routed
        if routed
          # Prevent default handling if the URL could be routed
          event.preventDefault()
        else
          # Navigate to the URL normally
          location.href = path
