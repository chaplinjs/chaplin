define [
  'jquery',
  'underscore',
  'backbone',
  'chaplin/mediator',
  'chaplin/lib/utils',
  'chaplin/lib/subscriber'
], ($, _, Backbone, mediator, utils, Subscriber) ->
  'use strict'

  class Layout # This class does not extend View

    # Borrow the static extend method from Backbone
    @extend = Backbone.Model.extend

    # Mixin a Subscriber
    _(@prototype).extend Subscriber

    # The site title used in the document title
    # This should be set in your app-specific Application class
    # and passed as an option
    title: ''

    # An hash to register events, like in Backbone.View
    # It is only meant for events that are app-wide
    # independent from any view
    events: {}

    # Register @el, @$el and @cid for delegating events
    el: document
    $el: $(document)
    cid: 'chaplin-layout'

    constructor: ->
      @initialize arguments...

    initialize: (options = {}) ->
      @title = options.title
      @settings = _(options).defaults
        titleTemplate: _.template("<%= subtitle %> \u2013 <%= title %>")
        openExternalToBlank: true
        routeLinks: 'a'
        skipRouting: '.noscript'
        scrollTo: [0, 0]

      @subscribeEvent 'beforeControllerDispose', @hideOldView
      @subscribeEvent 'startupController', @showNewView
      @subscribeEvent 'startupController', @adjustTitle

      # Set the app link routing
      if @settings.routeLinks
        @initLinkRouting()

      # Set app wide event handlers
      @delegateEvents()


    # Take (un)delegateEvents from Backbone
    # -------------------------------------
    delegateEvents: Backbone.View::delegateEvents
    undelegateEvents: Backbone.View::undelegateEvents


    # Controller startup and disposal
    # -------------------------------

    # Handler for the global beforeControllerDispose event
    hideOldView: (controller) ->
      # Jump to the top of the page
      scrollTo @settings.scrollTo if @settings.scrollTo

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
      title = @title or ''
      subtitle = context.controller.title or ''
      title = @settings.titleTemplate {title, subtitle}

      # Internet Explorer < 9 workaround
      setTimeout (-> document.title = title), 50


    # Automatic routing of internal links
    # -----------------------------------

    initLinkRouting: ->
      if @settings.routeLinks
        $(document).on 'click', @settings.routeLinks, _.bind(@openLink, this)

    stopLinkRouting: ->
      if @settings.routeLinks
        $(document).off 'click', @settings.routeLinks

    # Handle all clicks on A elements and try to route them internally
    openLink: (event) ->
      return if utils.modifierKeyPressed(event)

      el = event.currentTarget
      $el = $(el)
      href = el.getAttribute('href') or $(el).data('href') or null
      target = $(el).attr('target')


      # Link test ---------------
      skipRouting = @settings.skipRouting
      if typeof skipRouting is 'function'
        skipRouting = skipRouting(href)
      else if typeof skipRouting is 'string'
        skipRouting = $el.is(skipRouting)
      else
        skipRouting = skipRouting

      return if href is null or
                href is '' or
                href.charAt(0) is '#' or
                target is '_blank' or
                skipRouting


      # External link -----------
      currentHostname = location.hostname.replace('.', '\\.')
      external = not ///#{currentHostname}$///i.test(el.hostname)

      if external
        if @settings.openExternalToBlank
          event.preventDefault() and window.open el.href

        return


      # Internal link -----------
      if el.nodeName is 'A'
        path = el.pathname + el.search                  # path + query string
        path = "/#{path}" if path.charAt(0) isnt '/'    # starting '/' for IE8
        callback = (routed) -> event.preventDefault() if routed
      else
        path = href
        callback = (routed) -> if routed then event.preventDefault() else location.href = path

      # Pass to the router, try to route internally
      mediator.publish '!router:route', path, callback

      # mediator.publish '!router:route', path, (routed) ->
      #   event.preventDefault() if routed



    # Disposal
    # --------

    disposed: false

    dispose: ->
      return if @disposed

      @stopLinkRouting()
      @unsubscribeAllEvents()
      @undelegateEvents()

      delete @title

      @disposed = true

      # You’re frozen when your heart’s not open
      Object.freeze? this
