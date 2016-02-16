'use strict'

_ = require 'underscore'
Backbone = require 'backbone'

View = require './view'
EventBroker = require '../lib/event_broker'
utils = require '../lib/utils'
mediator = require '../mediator'

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
      titleTemplate: (data) ->
        st = if data.subtitle then "#{data.subtitle} \u2013 " else ''
        st + data.title
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
  scroll: ->
    # Reset the scroll position.
    to = @settings.scrollTo
    if to and typeof to is 'object'
      [x, y] = to
      window.scrollTo x, y

  # Handler for the global dispatcher:dispatch event.
  # Change the document title to match the new controller.
  # Get the title from the title property of the current controller.
  adjustTitle: (subtitle = '') ->
    title = @settings.titleTemplate {@title, subtitle}
    document.title = title
    @publishEvent 'adjustTitle', subtitle, title
    title

  # Automatic routing of internal links
  # -----------------------------------

  startLinkRouting: ->
    route = @settings.routeLinks
    return unless route
    if $
      @$el.on 'click', route, @openLink
    else
      @delegate 'click', route, @openLink

  stopLinkRouting: ->
    route = @settings.routeLinks
    if $
      @$el.off 'click', route if route
    else
      @undelegate 'click', route, @openLink

  isExternalLink: (link) ->
    # IE 9-11 resolve href but do not populate protocol, host etc.
    # Reassigning href helps. See #878 issue for details.
    link.href += '' unless link.host

    {protocol, host} = location
    {target} = link

    target is '_blank' or
    link.rel is 'external' or
    link.protocol isnt protocol or
    link.host isnt host or
    (target is '_parent' and parent isnt self) or
    (target is '_top' and top isnt self)

  # Handle all clicks on A elements and try to route them internally.
  openLink: (event) =>
    return if utils.modifierKeyPressed event

    el = if $ then event.currentTarget else event.delegateTarget

    # Get the href and perform checks on it.
    href = el.getAttribute('href') or el.getAttribute('data-href')

    # Basic href checks.
    return if href is null or
      # Technically an empty string is a valid relative URL
      # but it doesn’t make sense to route it.
      href is '' or
      # Exclude fragment links.
      href[0] is '#'

    # Apply skipRouting option.
    skipRouting = @settings.skipRouting
    type = typeof skipRouting
    return if type is 'function' and not skipRouting(href, el) or
      type is 'string' and (if $ then $(el).is(skipRouting)
      else Backbone.utils.matchesSelector el, skipRouting)

    # Handle external links.
    isAnchor = el.nodeName.toUpperCase() in ['A', 'AREA']
    external = isAnchor and @isExternalLink el
    if external
      if @settings.openExternalToBlank
        # Open external links normally in a new tab.
        event.preventDefault()
        @openWindow href
      return

    # Pass to the router, try to route the path internally.
    utils.redirectTo url: href

    # Prevent default handling if the URL could be routed.
    event.preventDefault()
    return

  # Handle all browsing context resources
  openWindow: (href) ->
    window.open href

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
    @globalRegions = (region for region in @globalRegions when (
      region.instance.cid isnt cid or region.name isnt name
    ))

  # When views are disposed; remove all their registered regions.
  unregisterGlobalRegions: (instance) ->
    @globalRegions = (region for region in @globalRegions when (
      region.instance.cid isnt instance.cid
    ))

  # Returns the region by its name, if found.
  regionByName: (name) ->
    for reg in @globalRegions when reg.name is name and not reg.instance.stale
      return reg

  # When views are instantiated and request for a region assignment;
  # attempt to fulfill it.
  showRegion: (name, instance) ->
    # Find an appropriate region.
    region = @regionByName name

    # Assert that we got a valid region.
    throw new Error "No region registered under #{name}" unless region

    # Apply the region selector.
    instance.container = if region.selector is ''
      if $
        region.instance.$el
      else
        region.instance.el
    else
      if region.instance.noWrap
        if $
          $(region.instance.container).find region.selector
        else
          region.instance.container.querySelector region.selector
      else
        region.instance[if $ then '$' else 'find'] region.selector

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
