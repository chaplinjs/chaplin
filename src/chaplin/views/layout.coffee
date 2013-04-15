'use strict'

_ = require 'underscore'
Backbone = require 'backbone'
utils = require 'chaplin/lib/utils'
EventBroker = require 'chaplin/lib/event_broker'
View = require 'chaplin/views/view'

# Shortcut to access the DOM manipulation library.
$ = Backbone.$

module.exports = class Layout extends View
  # The site title used in the document title.
  # This should be set in your app-specific Application class
  # and passed as an option.
  title: ''

  # Bind to document body by default.
  el: document.body

  # Override default view behavior, we don’t want document.body to be removed.
  keepElement: true

  # Regions
  # -------

  # Collection of registered regions; all view regions are collected here.
  globalRegions: null

  listen:
    'beforeControllerDispose mediator': 'scroll'
    '!adjustTitle mediator': 'adjustTitle'
    '!region:show mediator': 'showRegion'
    '!region:register mediator': 'registerRegionHandler'
    '!region:unregister mediator': 'unregisterRegionHandler'

  constructor: (options = {}) ->
    @globalRegions = []
    @title = options.title
    @regions = options.regions if options.regions
    @settings = _(options).defaults
      titleTemplate: _.template("<%= subtitle %> \u2013 <%= title %>")
      openExternalToBlank: false
      routeLinks: 'a, .go-to'
      skipRouting: '.noscript'
      # Per default, jump to the top of the page.
      scrollTo: [0, 0]
    @route = @settings.routeLinks

    super

    # Set the app link routing.
    @startLinkRouting() if @settings.routeLinks

  # Controller startup and disposal
  # -------------------------------

  # Handler for the global beforeControllerDispose event.
  scroll: (controller) ->
    # Reset the scroll position.
    scrollTo = @settings.scrollTo
    if scrollTo
      window.scrollTo scrollTo[0], scrollTo[1]

  # Handler for the global dispatcher:dispatch event.
  # Change the document title to match the new controller.
  # Get the title from the title property of the current controller.
  adjustTitle: (subtitle = '') ->
    title = @settings.titleTemplate {@title, subtitle}

    # Internet Explorer < 9 workaround.
    setTimeout (-> document.title = title), 50

  # Automatic routing of internal links
  # -----------------------------------

  startLinkRouting: ->
    @$el.on 'click', @route, @openLink if @route

  stopLinkRouting: ->
    @$el.off 'click', @route if @route

  isExternalLink: (link) ->
    link.target is '_blank' or
    link.rel is 'external' or
    link.protocol not in ['http:', 'https:', 'file:'] or
    link.hostname not in [location.hostname, '']

  # Handle all clicks on A elements and try to route them internally.
  openLink: (event) =>
    return if utils.modifierKeyPressed(event)

    el = event.currentTarget
    $el = $(el)
    isAnchor = el.nodeName is 'A'

    # Get the href and perform checks on it.
    href = $el.attr('href') or $el.data('href') or null

    # Basic href checks.
    return if href is null or href is undefined or
      # Technically an empty string is a valid relative URL
      # but it doesn’t make sense to route it.
      href is '' or
      # Exclude fragment links.
      href.charAt(0) is '#'

    # Apply skipRouting option.
    skipRouting = @settings.skipRouting
    type = typeof skipRouting
    return if type is 'function' and not skipRouting(href, el) or
      type is 'string' and $el.is skipRouting

    # Handle external links.
    external = isAnchor and @isExternalLink el
    if external
      if @settings.openExternalToBlank
        # Open external links normally in a new tab.
        event.preventDefault()
        window.open el.href
      return

    if isAnchor
      path = el.pathname
      query = el.search.substring 1
      # Append leading slash for IE8.
      path = "/#{path}" if path.charAt(0) isnt '/'
    else
      [path, query] = href.split '?'
      query ?= ''

    # Create routing options and callback.
    options = {query}
    callback = (routed) ->
      # Prevent default handling if the URL could be routed.
      if routed
        event.preventDefault()
      else unless isAnchor
        location.href = path
      return

    # Pass to the router, try to route the path internally.
    @publishEvent '!router:route', path, options, callback
    return

  # Region management
  # -----------------

  # Handler for `!region:register`.
  # Register a single view region or all regions exposed.
  registerRegionHandler: (instance, name, selector) ->
    if name?
      @registerGlobalRegion instance, name, selector
    else
      @registerGlobalRegions instance

  # Registering one region bound to a view.
  registerGlobalRegion: (instance, name, selector) ->
    # Remove the region if there was already one registered perhaps by
    # a base class.
    @unregisterGlobalRegion instance, name

    # Place this region registration into the regions array.
    @globalRegions.unshift {instance, name, selector}

  # Triggered by view; passed in the regions hash.
  # Simply register all regions exposed by it.
  registerGlobalRegions: (instance) ->
    # Regions can be be extended by subclasses, so we need to check the
    # whole prototype chain for matching regions. Regions registered by the
    # more-derived class overwrites the region registered by the less-derived
    # class.
    for version in utils.getAllPropertyVersions instance, 'regions'
      for selector, name of version
        @registerGlobalRegion instance, name, selector
    # Return nothing.
    return

  # Handler for `!region:unregister`.
  # Unregisters single named region or all view regions.
  unregisterRegionHandler: (instance, name) ->
    if name?
      @unregisterGlobalRegion instance, name
    else
      @unregisterGlobalRegions instance

  # Unregisters a specific named region from a view.
  unregisterGlobalRegion: (instance, name) ->
    cid = instance.cid
    @globalRegions = _.filter @globalRegions, (region) ->
      region.instance.cid isnt cid or region.name isnt name

  # When views are disposed; remove all their registered regions.
  unregisterGlobalRegions: (instance) ->
    @globalRegions = _.filter @globalRegions, (region) ->
      region.instance.cid isnt instance.cid

  # When views are instantiated and request for a region assignment;
  # attempt to fulfill it.
  showRegion: (name, instance) ->
    # Find an appropriate region.
    region = _.find @globalRegions, (region) ->
      region.name is name and not region.instance.stale

    # Assert that we got a valid region.
    throw new Error "No region registered under #{name}" unless region

    # Apply the region selector.
    instance.container = if region.selector is ''
      region.instance.$el
    else
      region.instance.$ region.selector

  # Disposal
  # --------

  dispose: ->
    return if @disposed

    # Stop routing links.
    @stopLinkRouting()

    # Remove all regions and document title setting.
    delete this[prop] for prop in ['globalRegions', 'title', 'route']

    super
