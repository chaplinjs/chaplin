'use strict'

Backbone = require 'backbone'
_ = require 'underscore'
support = require 'chaplin/lib/support'
utils = require 'chaplin/lib/utils'

# Mediator
# --------

# The mediator is a simple object all other modules use to communicate
# with each other. It implements the Publish/Subscribe pattern.
#
# Additionally, it holds objects which need to be shared between modules.
# In this case, a `user` property is created for getting the user object
# and a `setUser` method for setting the user.
#
# This module returns the singleton object. This is the
# application-wide mediator you might load into modules
# which need to talk to other modules using Publish/Subscribe.

# Start with a simple object
mediator = {}

# Publish / Subscribe
# -------------------

# Mixin event methods from Backbone.Events,
# create Publish/Subscribe aliases.
mediator.subscribe   = Backbone.Events.on
mediator.unsubscribe = Backbone.Events.off
mediator.publish     = Backbone.Events.trigger

# Initialize an empty callback list so we might seal the mediator later.
mediator._callbacks = null

# Request / Response
# --–---------------

# Like pub / sub, but with one handler. Similar to OOP message passing.

handlers = mediator._handlers = {}

# Sets a handler function for requests.
mediator.setHandler = (name, method, instance) ->
  handlers[name] = {instance, method}

# Retrieves a handler function and executes it.
mediator.execute = (nameOrObj, args...) ->
  silent = false
  if typeof nameOrObj is 'object'
    silent = nameOrObj.silent
    name = nameOrObj.name
  else
    name = nameOrObj
  handler = handlers[name]
  if handler
    handler.method.apply handler.instance, args
  else if not silent
    throw new Error "mediator.execute: #{name} handler is not defined"

# Removes handlers from storage.
# Can take no args, list of handler names or instance which had bound handlers.
mediator.removeHandlers = (instanceOrNames) ->
  unless instanceOrNames
    mediator._handlers = {}

  if utils.isArray instanceOrNames
    for name in instanceOrNames
      delete handlers[name]
  else
    for name, handler of handlers when handler.instance is instanceOrNames
      delete handlers[name]
  return

# Make properties readonly.
utils.readonly mediator,
  'subscribe', 'unsubscribe', 'publish', 'setHandler', 'execute', 'removeHandlers'

# Sealing the mediator
# --------------------

# After adding all needed properties, you should seal the mediator
# using this method.
mediator.seal = ->
  # Prevent extensions and make all properties non-configurable.
  if support.propertyDescriptors and Object.seal
    Object.seal mediator

# Make the method readonly.
utils.readonly mediator, 'seal'

# Return our creation.
module.exports = mediator
