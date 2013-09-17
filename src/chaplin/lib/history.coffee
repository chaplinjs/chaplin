'use strict'

_ = require 'underscore'
Backbone = require 'backbone'

# Cached regex for stripping a leading hash/slash and trailing space.
routeStripper = /^[#\/]|\s+$/g

# Cached regex for stripping leading and trailing slashes.
rootStripper = /^\/+|\/+$/g

# Cached regex for detecting MSIE.
isExplorer = /msie [\w.]+/

# Cached regex for removing a trailing slash.
trailingSlash = /\/$/

# Patched Backbone.History with a basic query strings support
module.exports = class History extends Backbone.History

  # Get the cross-browser normalized URL fragment, either from the URL,
  # the hash, or the override.
  getFragment: (fragment, forcePushState) ->
    if not fragment?
      if @_hasPushState or not @_wantsHashChange or forcePushState
        fragment = @location.pathname + @location.search
        root = @root.replace trailingSlash, ''
        fragment = fragment.substr root.length unless fragment.indexOf root
      else
        fragment = @getHash()

    fragment.replace routeStripper, ''

  # Start the hash change handling, returning `true` if the current URL matches
  # an existing route, and `false` otherwise.
  start: (options) ->
    throw new Error 'Backbone.history has already been started' if Backbone.History.started
    Backbone.History.started = true

    # Figure out the initial configuration. Do we need an iframe?
    # Is pushState desired ... is it available?
    @options          = _.extend {}, {root: '/'}, @options, options
    @root             = @options.root
    @_wantsHashChange = @options.hashChange isnt false
    @_wantsPushState  = not not @options.pushState
    @_hasPushState    = not not (@options.pushState and @history and @history.pushState)
    fragment          = @getFragment()
    docMode           = document.documentMode
    oldIE             = isExplorer.exec(navigator.userAgent.toLowerCase()) and (not docMode or docMode <= 7)

    # Normalize root to always include a leading and trailing slash.
    @root = ('/' + @root + '/').replace rootStripper, '/'

    if oldIE and @._wantsHashChange
      @iframe = Backbone.$('<iframe src="javascript:0" tabindex="-1" />').hide().appendTo('body')[0].contentWindow
      @navigate fragment

    # Depending on whether we're using pushState or hashes, and whether
    # 'onhashchange' is supported, determine how we check the URL state.
    if (@_hasPushState)
      Backbone.$(window).on 'popstate', @checkUrl
    else if @_wantsHashChange and 'onhashchange' in window and not oldIE
      Backbone.$(window).on 'hashchange', @checkUrl
    else if @_wantsHashChange
      @_checkUrlInterval = setInterval @checkUrl, @interval

    # Determine if we need to change the base url, for a pushState link
    # opened by a non-pushState browser.
    @fragment = fragment
    loc = @location
    atRoot = loc.pathname.replace(/[^\/]$/, '$&/') is @root

    # If we've started off with a route from a `pushState`-enabled browser,
    # but we're currently in a browser that doesn't support it...
    if @_wantsHashChange and @_wantsPushState and not @_hasPushState and not atRoot
      @fragment = @getFragment null, true
      @location.replace @root + '#' + @fragment
      # Return immediately as browser will do redirect to new url
      return true

    # Or if we've started out with a hash-based route, but we're currently
    # in a browser where it could be `pushState`-based instead...
    else if @_wantsPushState and @_hasPushState and atRoot and loc.hash
      @fragment = @getHash().replace routeStripper, ''
      @history.replaceState {}, document.title, @root + @fragment

    @loadUrl() if not @options.silent
