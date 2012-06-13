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
        openExternalLinksInNewWindow: true
        linkTest: false
        scrollTo: [0, 0]

      @subscribeEvent 'beforeControllerDispose', @hideOldView
      @subscribeEvent 'startupController', @showNewView
      @subscribeEvent 'startupController', @adjustTitle

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
      title = @title || ''
      subtitle = context.controller.title || ''

      title = @settings.titleTemplate
        title: title
        subtitle: subtitle

      # Internet Explorer < 9 workaround
      setTimeout (-> document.title = title), 50


    # Automatic routing of internal links
    # -----------------------------------

    # Handle all clicks on A elements and try to route them internally
    openLink: (event) ->
      return if utils.modifierKeyPressed(event)

      el = event.currentTarget
      $el = $(el)
      href = el.getAttribute('href') || $(el).data('href') || null

      # Link test ---------------
      hrefTest = if _.isFunction(@settings.linkTest) then @settings.linkTest(href) else @settings.linkTest
      return if href is null or
                href is '' or
                href.charAt(0) is '#' or
                hrefTest


      # External link -----------
      currentHostname = location.hostname.replace('.', '\\.')
      external = not ///#{currentHostname}$///i.test(el.hostname)

      if external
        if @settings.openExternalLinksInNewWindow
          event.preventDefault() && window.open el.href

        return


      # Internal link -----------
      path = el.pathname + el.search                  # path + query string
      path = "/#{path}" if path.charAt(0) isnt '/'    # starting '/' for IE8

      # Pass to the router, try to route internally
      mediator.publish '!router:route', path, (routed) ->
        event.preventDefault() if routed



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
