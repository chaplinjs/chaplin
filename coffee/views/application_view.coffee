define ['mediator', 'lib/utils'], (mediator, utils) ->
  'use strict'

  class ApplicationView # Do not inherit from View

    # Set your application name here so
    # the document title is set properly to
    # “Site title – Controller title” (see adjustTitle)
    siteTitle = 'Chaplin Example Application'

    constructor: ->
      console.debug 'ApplicationView#constructor'
      # Listen to global events
      mediator.subscribe 'login', @updateBodyClasses
      mediator.subscribe 'logout', @updateBodyClasses
      mediator.subscribe 'beforeControllerDispose', @hideOldView
      mediator.subscribe 'startupController', @showNewView
      mediator.subscribe 'startupController', @removeFallbackContent
      mediator.subscribe 'startupController', @adjustTitle

      @updateBodyClasses()
      @addDOMHandlers()

    # Controller startup and disposal
    # -------------------------------

    # Handler for the global beforeControllerDispose event
    hideOldView: (controller) ->
      # Jump to the top of the page
      scrollTo 0, 0

      # Hide the container element of the current view
      view = controller.view
      if view and view.$container
        view.$container.css 'display', 'none'

    # Handler for the global startupController event
    # Show the container element of the new view
    showNewView: (info) ->
      view = info.controller.view
      if view and view.$container
        view.$container.css display: 'block', opacity: 1

    # Handler for the global startupController event
    # Change the document title to match the new controller
    # Get the title from the title property of the current controller
    adjustTitle: (info) ->
      console.debug 'ApplicationView#adjustTitle', info
      title = siteTitle
      subtitle = info.controller.title
      title = "#{subtitle} \u2013 #{title}" if subtitle
      # Internet Explorer < 9 workaround
      setTimeout (-> document.title = title), 50


    # Logged-in / logged-out classes for the body element
    # ---------------------------------------------------

    updateBodyClasses: =>
      body = $(document.body)
      loggedIn = Boolean mediator.user
      body.toggleClass('logged-out', loggedIn).toggleClass('logged-in', loggedIn)

    # Fallback content
    # ----------------

    # After the first controller has been started, remove all accessible
    # content so the DOM is less complex and images and video do not lie
    # in the background

    removeFallbackContent: =>
      # Hide fallback content and the loading screens
      $('.accessible-fallback').remove()

      # Remove the handler after the first startupController event
      mediator.unsubscribe 'startupController', @removeFallbackContent

    # DOM Event handling
    # ------------------

    addDOMHandlers: ->
      # Handle links
      $(document)
        .delegate('#logout-button', 'click', @logoutButtonClick)
        .delegate('.go-to', 'click', @goToHandler)
        .delegate('a', 'click', @openLink)

    # Handle all clicks on A elements and try to route them internally

    openLink: (event) =>
      el = event.currentTarget

      # Handle empty href
      hrefAttr = el.getAttribute 'href'
      return if hrefAttr is '' or /^#/.test(hrefAttr)

      # Is it an external link?
      href = el.href
      hostname = el.hostname
      return unless href and hostname
      currentHostname = location.hostname.replace('.', '\\.')
      hostnameRegExp = ///#{currentHostname}$///i
      external = not hostnameRegExp.test(hostname)
      if external
        # Open external links normally
        # You might want to enforce opening in a new tab here:
        # event.preventDefault()
        # window.open href
        return

      @openInternalLink event

    # Try to route a click on a link internally

    openInternalLink: (event) ->
      event.preventDefault()
      el = event.currentTarget

      path = el.pathname
      return unless path

      # Pass to the router. Returns true if the URL could be routed.
      result = mediator.router.route path

      event.preventDefault() if result

    # Not only A elements might act as internal links,
    # every element might have:
    # class="go-to" data-href="/something"

    goToHandler: (event) ->
      el = event.currentTarget

      # Do not handle A elements
      return if event.nodeName is 'A'

      path = $(el).data('href')
      return unless path

      # Pass to the router. Returns true if the URL could be routed.
      result = mediator.router.route path

      event.preventDefault() if result

    # Handle clicks on the logout button

    logoutButtonClick: (event) ->
      event.preventDefault()

      # Publish a global !logout event
      mediator.publish '!logout'
