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
    true

  # Get the whole chain of object prototypes.
  getPrototypeChain: (object) ->
    chain = []
    while object = Object.getPrototypeOf object
      chain.unshift object
    chain

  # Get all property versions from object’s prototype chain.
  # E.g. if object1 & object2 have `prop` and object2 inherits from
  # object1, it will get [object1prop, object2prop].
  getAllPropertyVersions: (object, property) ->
    result = []
    for proto in utils.getPrototypeChain object
      value = proto[property]
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
    {require} = window

    if typeof define is 'function' and define.amd
      (moduleName, handler) ->
        require [moduleName], handler
    else
      enqueue = setImmediate ? setTimeout

      (moduleName, handler) ->
        enqueue ->
          handler require moduleName


  # Query parameters Helpers
  # --------------

  querystring:

    # Returns a query string from a hash
    stringify: (queryParams) ->
      query = ''
      stringifyKeyValuePair = (encodedKey, value) ->
        if value? then '&' + encodedKey + '=' + encodeURIComponent value else ''
      for own key, value of queryParams
        encodedKey = encodeURIComponent key
        if utils.isArray value
          for arrParam in value
            query += stringifyKeyValuePair encodedKey, arrParam
        else
          query += stringifyKeyValuePair encodedKey, value
      query and query.slice 1

    # Returns a hash with query parameters from a query string
    parse: (queryString) ->
      params = {}
      return params unless queryString
      queryString = queryString.slice queryString.indexOf('?') + 1
      pairs = queryString.split '&'
      for pair in pairs
        continue unless pair.length
        [field, value] = pair.split '='
        continue unless field.length
        field = decodeURIComponent field
        value = decodeURIComponent value
        current = params[field]
        if current
          # Handle multiple params with same name:
          # Aggregate them in an array.
          if current.push
            # Add the existing array.
            current.push value
          else
            # Create a new array.
            params[field] = [current, value]
        else
          params[field] = value

      params


# Backwards-compatibility methods
# -------------------------------

utils.beget = Object.create
utils.queryParams = utils.querystring
utils.indexOf = (array, item) -> array.indexOf item
utils.isArray = Array.isArray

# Finish
# ------

# Seal the utils object.
Object.seal utils

# Return our creation.
module.exports = utils
