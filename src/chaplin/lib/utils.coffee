'use strict'

# Utilities
# ---------

utils =
  isEmpty: (object) ->
    not Object.getOwnPropertyNames(object).length

  # Simple duck-typing serializer for models and collections.
  serialize: (data) ->
    if typeof data.serialize is 'function'
      data.serialize()
    else if typeof data.toJSON is 'function'
      data.toJSON()
    else
      throw new TypeError 'utils.serialize: Unknown data was passed'

  # Make properties readonly and not configurable
  # using ECMAScript 5 property descriptors.
  readonly: (object, keys...) ->
    for key in keys
      Object.defineProperty object, key,
        value: object[key]
        writable: false
        configurable: false
    # Always return `true` for compatibility reasons.
    true

  # Get the whole chain of object prototypes.
  getPrototypeChain: (object) ->
    chain = []
    while object = Object.getPrototypeOf object
      chain.unshift object
    chain

  # Get all property versions from object’s prototype chain.
  # E.g. if object1 & object2 have `key` and object2 inherits from
  # object1, it will get [object1prop, object2prop].
  getAllPropertyVersions: (object, key) ->
    result = []
    for proto in utils.getPrototypeChain object
      value = proto[key]
      if value and value not in result
        result.push value
    result

  # String Helpers
  # --------------

  # Upcase the first character.
  upcase: (str) ->
    str.charAt(0).toUpperCase() + str.slice 1

  # Escapes a string to use in a regex.
  escapeRegExp: (str) ->
    return String(str or '').replace /([.*+?^=!:${}()|[\]\/\\])/g, '\\$1'


  # Event handling helpers
  # ----------------------

  # Returns whether a modifier key is pressed during a keypress or mouse click.
  modifierKeyPressed: (event) ->
    event.shiftKey or event.altKey or event.ctrlKey or event.metaKey

  # Routing Helpers
  # ---------------

  # Returns the url for a named route and any params.
  reverse: (criteria, params, query) ->
    require('../mediator').execute 'router:reverse',
      criteria, params, query

  # Redirects to URL, route name or controller and action pair.
  redirectTo: (pathDesc, params, options) ->
    require('../mediator').execute 'router:route',
      pathDesc, params, options

  # Determines module system and returns module loader function.
  loadModule: do ->
    {define, require} = window

    if typeof define is 'function' and define.amd
      (moduleName, handler) ->
        require [moduleName], handler
    else
      enqueue = setImmediate ? setTimeout

      (moduleName, handler) ->
        enqueue -> handler require moduleName

  # DOM helpers
  # -----------

  matchesSelector: do ->
    el = document.documentElement
    matches = el.matches or
    el.msMatchesSelector or
    el.mozMatchesSelector or
    el.webkitMatchesSelector

    -> matches.call arguments...

  # Query parameters Helpers
  # ------------------------

  querystring:

    # Returns a query string from a hash.
    stringify: (params = {}, replacer) ->
      if typeof replacer isnt 'function'
        replacer = (key, value) ->
          if Array.isArray value
            value.map (value) -> {key, value}
          else if value?
            {key, value}

      Object.keys(params).reduce (pairs, key) ->
        pair = replacer key, params[key]
        pairs.concat pair or []
      , []
      .map ({key, value}) ->
        [key, value].map(encodeURIComponent).join '='
      .join '&'

    # Returns a hash with query parameters from a query string.
    parse: (string = '', reviver) ->
      if typeof reviver isnt 'function'
        reviver = (key, value) -> {key, value}

      string = string.slice 1 + string.indexOf '?'
      string.split('&').reduce (params, pair) ->
        parts = pair.split('=').map decodeURIComponent
        {key, value} = reviver(parts...) or {}

        if value? then params[key] =
          if params.hasOwnProperty key
            [].concat params[key], value
          else
            value

        params
      , {}


# Backwards-compatibility methods
# -------------------------------

utils.beget = Object.create
utils.indexOf = (array, item) -> array.indexOf item
utils.isArray = Array.isArray
utils.queryParams = utils.querystring

# Finish
# ------

# Seal the utils object.
Object.seal utils

# Return our creation.
module.exports = utils
