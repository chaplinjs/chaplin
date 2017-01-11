import _ from 'underscore'
import Backbone from 'backbone'

# Cached regex for stripping a leading hash/slash and trailing space.
routeStripper = /^[#\/]|\s+$/g

# Cached regex for stripping leading and trailing slashes.
rootStripper = /^\/+|\/+$/g

# Patched Backbone.History with a basic query strings support
class History extends Backbone.History

  # Get the cross-browser normalized URL fragment, either from the URL,
  # the hash, or the override.
  getFragment: (fragment, forcePushState) ->
    if not fragment?
      if @_hasPushState or not @_wantsHashChange or forcePushState
        # CHANGED: Make fragment include query string.
        fragment = @location.pathname + @location.search
        # Remove trailing slash.
        root = @root.replace /\/$/, ''
        fragment = fragment.slice root.length unless fragment.indexOf root
      else
        fragment = @getHash()

    fragment.replace routeStripper, ''

  # Start the hash change handling, returning `true` if the current URL matches
  # an existing route, and `false` otherwise.
  start: (options) ->
    if Backbone.History.started
      throw new Error 'Backbone.history has already been started'
    Backbone.History.started = true

    # Figure out the initial configuration. Is pushState desired?
    # Is it available? Are custom strippers provided?
    @options          = _.extend {}, {root: '/'}, @options, options
    @root             = @options.root
    @_wantsHashChange = @options.hashChange isnt false
    @_wantsPushState  = Boolean @options.pushState
    @_hasPushState    = Boolean @options.pushState and @history?.pushState
    fragment          = @getFragment()
    routeStripper     = @options.routeStripper ? routeStripper
    rootStripper      = @options.rootStripper ? rootStripper

    # Normalize root to always include a leading and trailing slash.
    @root = ('/' + @root + '/').replace rootStripper, '/'

    # Depending on whether we're using pushState or hashes,
    # determine how we check the URL state.
    if @_hasPushState
      Backbone.$(window).on 'popstate', @checkUrl
    else if @_wantsHashChange
      Backbone.$(window).on 'hashchange', @checkUrl

    # Determine if we need to change the base url, for a pushState link
    # opened by a non-pushState browser.
    @fragment = fragment
    loc = @location
    atRoot = loc.pathname.replace(/[^\/]$/, '$&/') is @root

    # If we've started off with a route from a `pushState`-enabled browser,
    # but we're currently in a browser that doesn't support it...
    if @_wantsHashChange and @_wantsPushState and
    not @_hasPushState and not atRoot
      # CHANGED: Prevent query string from being added before hash.
      # So, it will appear only after #, as it has been already included
      # into @fragment
      @fragment = @getFragment null, true
      @location.replace @root + '#' + @fragment
      # Return immediately as browser will do redirect to new url
      return true

    # Or if we've started out with a hash-based route, but we're currently
    # in a browser where it could be `pushState`-based instead...
    else if @_wantsPushState and @_hasPushState and atRoot and loc.hash
      @fragment = @getHash().replace routeStripper, ''
      # CHANGED: It's no longer needed to add loc.search at the end,
      # as query params have been already included into @fragment
      @history.replaceState {}, document.title, @root + @fragment

    @loadUrl() if not @options.silent

  navigate: (fragment = '', options) ->
    return false unless Backbone.History.started

    options = {trigger: options} if not options or options is true

    fragment = @getFragment fragment
    url = @root + fragment

    # Remove fragment replace, coz query string different mean difference page
    # Strip the fragment of the query and hash for matching.
    # fragment = fragment.replace(pathStripper, '')

    return false if @fragment is fragment
    @fragment = fragment

    # Don't include a trailing slash on the root.
    if fragment.length is 0 and url isnt @root
      url = url.slice 0, -1

    # If pushState is available, we use it to set the fragment as a real URL.
    if @_hasPushState
      historyMethod = if options.replace then 'replaceState' else 'pushState'
      @history[historyMethod] {}, document.title, url

    # If hash changes haven't been explicitly disabled, update the hash
    # fragment to store history.
    else if @_wantsHashChange
      @_updateHash @location, fragment, options.replace

    # If you've told us that you explicitly don't want fallback hashchange-
    # based history, then `navigate` becomes a page refresh.
    else
      return @location.assign url

    if options.trigger
      @loadUrl fragment

History = if Backbone.$ then History else Backbone.History

export default History
