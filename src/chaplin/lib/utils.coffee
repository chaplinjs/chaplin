'use strict'

support = require 'chaplin/lib/support'

# Utilities
# ---------

utils =

  # Object Helpers
  # --------------

  # Prototypal delegation. Create an object which delegates
  # to another object.
  beget: do ->
    if typeof Object.create is 'function'
      Object.create
    else
      ctor = ->
      (obj) ->
        ctor.prototype = obj
        new ctor

  # Simple duck-typing serializer for models and collections.
  serialize: (data) ->
    if typeof data.serialize is 'function'
      data.serialize()
    else if typeof data.toJSON is 'function'
      data.toJSON()
    else
      throw new TypeError 'utils.serialize: Unknown data was passed'

  # Make properties readonly and not configurable
  # using ECMAScript 5 property descriptors
  readonly: do ->
    if support.propertyDescriptors
      readonlyDescriptor =
        writable: false
        enumerable: true
        configurable: false
      (obj, properties...) ->
        for prop in properties
          readonlyDescriptor.value = obj[prop]
          Object.defineProperty obj, prop, readonlyDescriptor
        true
    else
      ->
        false

  # Get the whole chain of object prototypes.
  getPrototypeChain: (object) ->
    chain = [object.constructor.prototype]
    chain.push object while object = object.constructor?.__super__
    chain

  # Get all property versions from object’s prototype chain.
  # E.g. if object1 & object2 have `prop` and object2 inherits from
  # object1, it will get [object1prop, object2prop].
  getAllPropertyVersions: (object, property) ->
    _(utils.getPrototypeChain object)
      .chain()
      .pluck(property)
      .compact()
      .uniq()
      .value()
      .reverse()

  # Function Helpers
  # ----------------

  # Wrap a method in order to call the corresponding
  # `after-` method automatically (e.g. `afterRender` or
  # `afterInitialize`)
  wrapMethod: (instance, name) ->
    # Enclose the original function
    func = instance[name]
    # Set a flag
    instance["#{name}IsWrapped"] = true
    # Create the wrapper method
    instance[name] = ->
      # Stop if the instance was already disposed
      return false if instance.disposed
      # Call the original method
      func.apply instance, arguments
      # Call the corresponding `after-` method
      instance["after#{utils.upcase(name)}"] arguments...
      # Return the view
      instance

  # String Helpers
  # --------------

  # Upcase the first character
  upcase: (str) ->
    str.charAt(0).toUpperCase() + str.substring(1)

  # underScoreHelper -> under_score_helper
  underscorize: (string) ->
    string.replace /[A-Z]/g, (char, index) ->
      (if index isnt 0 then '_' else '') + char.toLowerCase()

  # Event handling helpers
  # ----------------------

  # Returns whether a modifier key is pressed during a keypress or mouse click
  modifierKeyPressed: (event) ->
    event.shiftKey or event.altKey or event.ctrlKey or event.metaKey

# Finish
# ------

# Seal the utils object
Object.seal? utils

# Return our creation
module.exports = utils
