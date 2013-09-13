'use strict'

_ = require 'underscore'
Backbone = require 'backbone'
mediator = require 'chaplin/mediator'
helpers = require 'chaplin/lib/helpers'
utils = require 'chaplin/lib/utils'
EventBroker = require 'chaplin/lib/event_broker'
View = require 'chaplin/views/view'

# Shortcut to access the DOM manipulation library.
$ = Backbone.$

module.exports = class Layout extends View
  # Bind to document body by default.
  el: 'body'

  # Override default view behavior, we don’t want document.body to be removed.
  keepElement: true

  # The site title used in the document title.
  # This should be set in your app-specific Application class
  # and passed as an option.
  title: ''

  # Regions
  # -------

  # Collection of registered regions; all view regions are collected here.
  globalRegions: null

  listen:
    'beforeControllerDispose mediator': 'scroll'

  constructor: (options = {}) ->
    @globalRegions = []
    @title = options.title
    @regions = options.regions if options.regions
    @settings = _.defaults options,
      titleTemplate: _.template(
        "<% if (subtitle) { %><%= subtitle %> \u2013 <% } %><%= title %>"
      )
      openExternalToBlank: false
      routeLinks: 'a, .go-to'
      skipRouting: '.noscript'
      # Per default, jump to the top of the page.
      scrollTo: [0, 0]

    mediator.setHandler 'region:show', @showRegion, this
    mediator.setHandler 'region:register', @registerRegionHandler, this
    mediator.setHandler 'region:unregister', @unregisterRegionHandler, this
    mediator.setHandler 'region:find', @regionByName, this
    mediator.setHandler 'adjustTitle', @adjustTitle, this

    super

    # Set the app link routing.
    @startLinkRouting() if @settings.routeLinks

  # Controller startup and disposal
  # -------------------------------

  # Handler for the global beforeControllerDispose event.
  scroll: (controller) ->
    # Reset the scroll position.
    position = @settings.scrollTo
    if position
      window.scrollTo position[0], position[1]

  # Handler for the global dispatcher:dispatch event.
  # Change the document title to match the new controller.
  # Get the title from the title property of the current controller.
  adjustTitle: (subtitle = '') ->
    title = @settings.titleTemplate {@title, subtitle}
    # Internet Explorer < 9 workaround.
    setTimeout =>
      document.title = title
      @publishEvent 'adjustTitle', subtitle, title
    , 50
    title

  # Automatic routing of internal links
  # -----------------------------------

  startLinkRouting: ->
    route = @settings.routeLinks
    @$el.on 'click', route, @openLink if route

  stopLinkRouting: ->
    route = @settings.routeLinks
    @$el.off 'click', route if route

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
    return if not href? or
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
        window.open href
      return

    # Pass to the router, try to route the path internally.
    helpers.redirectTo url: href
    
    # Prevent default handling if the URL could be routed.
    event.preventDefault()
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
      for name, selector of version
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

  # Returns the region by its name, if found.
  regionByName: (name) ->
    _.find @globalRegions, (region) ->
      region.name is name and not region.instance.stale

  # When views are instantiated and request for a region assignment;
  # attempt to fulfill it.
  showRegion: (name, instance) ->
    # Find an appropriate region.
    region = @regionByName name

    # Assert that we got a valid region.
    throw new Error "No region registered under #{name}" unless region

    # Apply the region selector.
    instance.container = if region.selector is ''
      region.instance.$el
    else
      if region.instance.noWrap
        $(region.instance.container).find region.selector
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

    mediator.removeHandlers this

    super
