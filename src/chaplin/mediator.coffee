import Backbone from 'backbone'
import utils from './lib/utils'

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
mediator.subscribe     = mediator.on      = Backbone.Events.on
mediator.subscribeOnce = mediator.once    = Backbone.Events.once
mediator.unsubscribe   = mediator.off     = Backbone.Events.off
mediator.publish       = mediator.trigger = Backbone.Events.trigger

# Initialize an empty callback list so we might seal the mediator later.
mediator._callbacks = null

# Request / Response
# --–---------------

# Like pub / sub, but with one handler. Similar to OOP message passing.

handlers = mediator._handlers = {}

# Sets a handler function for requests.
mediator.setHandler = (name, method, instance) ->
  handlers[name] = {method, instance}

# Retrieves a handler function and executes it.
mediator.execute = (options, args...) ->
  if options and typeof options is 'object'
    {name, silent} = options
  else
    name = options
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

  if Array.isArray instanceOrNames
    for name in instanceOrNames
      delete handlers[name]
  else
    for name, handler of handlers when handler.instance is instanceOrNames
      delete handlers[name]
  return

# Sealing the mediator
# --------------------

# After adding all needed properties, you should seal the mediator
# using this method.
mediator.seal = ->
  # Prevent extensions and make all properties non-configurable.
  Object.seal mediator

# Make properties readonly.
utils.readonly mediator,
  'subscribe', 'subscribeOnce', 'unsubscribe', 'publish',
  'setHandler', 'execute', 'removeHandlers', 'seal'

# Return our creation.
export default mediator
