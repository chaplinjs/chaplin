define [
  'chaplin/lib/support'
], (support) ->
  'use strict'

  # Private helper methods
  # ----------------------

  # Private helper function for serializing attributes recursively,
  # creating objects which delegate to the original attributes
  # in order to protect them from changes.
  serializeAttributes = (model, attributes, modelStack) ->
    # Create a delegator object
    delegator = utils.beget attributes

    # Add model to stack
    if modelStack
      modelStack.push model
    else
      modelStack = [model]

    # Map model/collection to their attributes. Create a property
    # on the delegator that shadows the original attribute.
    for key, value of attributes

      # Handle models
      if value instanceof Backbone.Model
        delegator[key] = serializeModelAttributes value, model, modelStack

      # Handle collections
      else if value instanceof Backbone.Collection
        serializedModels = []
        for otherModel in value.models
          serializedModels.push(
            serializeModelAttributes(otherModel, model, modelStack)
          )
        delegator[key] = serializedModels

    # Remove model from stack
    modelStack.pop()

    # Return the delegator
    delegator

  # Serialize the attributes of a given model
  # in the context of a given tree
  serializeModelAttributes = (model, currentModel, modelStack) ->
    # Nullify circular references
    return null if model is currentModel or model in modelStack
    # Serialize recursively
    attributes = if typeof model.getAttributes is 'function'
      # Chaplin models
      model.getAttributes()
    else
      # Backbone models
      model.attributes
    serializeAttributes model, attributes, modelStack

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
          ctor:: = obj
          new ctor

    # Simple duck-typing serializer for models and collections.
    serialize: (store) ->
      # Get the attributes using the chaplin getAttributes or just using the
      # attributes property
      attributes = if typeof store.getAttributes is 'function'
        store.getAttributes()
      else
        store.attributes

      # Serialize the store attributes appropriately
      serializeAttributes store, attributes

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
      chain = [object]
      chain.push object while object = object.constructor?.__super__
      chain

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

  utils
