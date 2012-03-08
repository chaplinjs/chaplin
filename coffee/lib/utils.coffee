define ['mediator'], (mediator) ->

  'use strict'

  utils =
    # Object Helpers
    # --------------

    beget: (obj) ->
      ctor = ->
      ctor:: = obj
      new ctor

    # String Helpers
    # --------------

    # camel-case-helper > camelCaseHelper
    camelize: do ->
      regexp = /[-_]([a-z])/g
      camelizer = (match, c) ->
        c.toUpperCase()
      (string) ->
        string.replace regexp, camelizer

    # Upcase the first character
    upcase: (str) ->
      str.charAt(0).toUpperCase() + str.substring(1)

    # underScoreHelper -> under_score_helper
    underscorize: do ->
      regexp = /[A-Z]/g
      underscorizer = (c) ->
        '_' + c.toLowerCase()
      (string) ->
        string.replace regexp, underscorizer

    # Facebook image helper
    # ---------------------

    facebookImageURL: (fbId, type = 'square') ->
      # Create query string
      params = type: type

      # Add the Facebook access token if present
      if mediator.user
        accessToken = mediator.user.get('accessToken')
        params.access_token = accessToken if accessToken

      "https://graph.facebook.com/#{fbId}/picture?#{$.param(params)}"

    # Persistent data storage
    # -----------------------

    # sessionStorage with session cookie fallback
    # sessionStorage(key) gets the value for 'key'
    # sessionStorage(key, value) set the value for 'key'
    sessionStorage: do ->
      if window.sessionStorage and sessionStorage.getItem and
      sessionStorage.setItem and sessionStorage.removeItem
        (key, value) ->
          if typeof value is 'undefined'
            value = sessionStorage.getItem(key)
            if value? and value.toString then value.toString() else value
          else
            sessionStorage.setItem(key, value)
            value
      else
        (key, value) ->
          if typeof value is 'undefined'
            utils.getCookie(key)
          else
            utils.setCookie(key, value)
            value

    # sessionStorageRemove(key) removes the storage entry for 'key'
    sessionStorageRemove: do ->
      if window.sessionStorage and sessionStorage.getItem and
      sessionStorage.setItem and sessionStorage.removeItem
        (key) -> sessionStorage.removeItem(key)
      else
        (key) -> utils.expireCookie(key)

    # Cookie fallback
    # ---------------

    # Get a cookie by its name
    getCookie: (key) ->
      keyPosition = document.cookie.indexOf "#{key}="
      return false if keyPosition is -1
      start = keyPosition + key.length + 1
      end = document.cookie.indexOf ';', start
      end = document.cookie.length if end is -1
      decodeURIComponent(document.cookie.substring(start, end))

    # Set a session cookie

    setCookie: (key, value) ->
      document.cookie = key + '=' + encodeURIComponent(value)

    expireCookie: (key) ->
      document.cookie = "#{key}=nil; expires=#{(new Date).toGMTString()}"

    # Load additonal JavaScripts
    # We don’t use jQuery here because jQuery does not attach an error
    # handler to the script. In jQuery, a proper error handler only works
    # for same-origin scripts which can be loaded via XHR.
    loadLib: (url, success, error, timeout = 7500) ->
      head = document.head or document.getElementsByTagName('head')[0] or
      document.documentElement
      script = document.createElement 'script'
      script.async = 'async'
      script.src   = url

      onload = (_, aborted = false) ->
        return unless (aborted or
        not script.readyState or script.readyState is 'complete')

        clearTimeout timeoutHandle

        # Handle memory leak in IE
        script.onload = script.onreadystatechange = script.onerror = null
        # Remove the script elem and its reference
        head.removeChild(script) if head and script.parentNode
        script = undefined

        success() if success and not aborted

      script.onload = script.onreadystatechange = onload

      # This is what jQuery is missing
      script.onerror = ->
        onload null, true
        error() if error

      timeoutHandle = setTimeout script.onerror, timeout
      head.insertBefore script, head.firstChild

    # Functional helpers for handling asynchronous dependancies and I/O
    # -----------------------------------------------------------------

    ###
    Wrap methods so they can be called before a deferred is resolved.
    The actual methods are called once the deferred is resolved.

    Parameters:

    Expects an options hash with the following properties:

    deferred
      The Deferred object to wait for.

    methods
      Either:
      - A string with a method name e.g. 'method'
      - An array of strings e.g. ['method1', 'method2']
      - An object with methods e.g. {method: -> alert('resolved!')}

    host (optional)
      If you pass an array of strings in the `methods` parameter the methods
      are fetched from this object. Defaults to `deferred`.

    target (optional)
      The target object the new wrapper methods are created at.
      Defaults to host if host is given, otherwise it defaults to deferred.

    onDeferral (optional)
      An additional callback function which is invoked when the method is called
      and the Deferred isn't resolved yet.
      After the method is registered as a done handler on the Deferred,
      this callback is invoked. This can be used to trigger the resolving
      of the Deferred.

    Examples:

    deferMethods(deferred: def, methods: 'foo')
      Wrap the method named foo of the given deferred def and
      postpone all calls until the deferred is resolved.

    deferMethods(deferred: def, methods: def.specialMethods)
      Read all methods from the hash def.specialMethods and
      create wrapped methods with the same names at def.

    deferMethods(
      deferred: def, methods: def.specialMethods, target: def.specialMethods
    )
      Read all methods from the object def.specialMethods and
      create wrapped methods at def.specialMethods,
      overwriting the existing ones.

    deferMethods(deferred: def, host: obj, methods: ['foo', 'bar'])
      Wrap the methods obj.foo and obj.bar so all calls to them are postponed
      until def is resolved. obj.foo and obj.bar are overwritten
      with their wrappers.

    ###
    deferMethods: (options) ->
      # Process options
      deferred = options.deferred
      methods = options.methods
      host = options.host or deferred
      target = options.target or host
      onDeferral = options.onDeferral

      # Hash with named functions
      methodsHash = {}

      if typeof methods is 'string'
        # Transform a single method string into an object
        methodsHash[methods] = host[methods]

      else if methods.length and methods[0]
        # Transform a method list into an object
        for name in methods
          func = host[name]
          unless typeof func is 'function'
            throw new TypeError "utils.deferMethods: method #{name} not 
found on host #{host}"
          methodsHash[name] = func

      else
        # Treat methods parameter as a hash, no transformation
        methodsHash = methods

      # Process the hash
      for own name, func of methodsHash
        # Ignore non-function properties
        continue unless typeof func is 'function'
        # Replace method with wrapper
        target[name] = utils.createDeferredFunction(
          deferred, func, target, onDeferral
        )

    # Creates a function which wraps `func` and defers calls to
    # it until the given `deferred` is resolved. Pass an optional `context`
    # to determine the this `this` binding of the original function.
    # Defaults to `deferred`. The optional `onDeferral` function to after
    # original function is registered as a done callback.
    createDeferredFunction: (deferred, func, context = deferred, onDeferral) ->
      # Return a wrapper function
      ->
        # Save the original arguments
        args = arguments
        if deferred.state() is 'resolved'
          # Deferred already resolved, call func immediately
          func.apply context, args
        else
          # Register a done handler
          deferred.done ->
            func.apply context, args
          # Invoke the onDeferral callback
          if typeof onDeferral is 'function'
            onDeferral.apply context

    # Accumulators
    accumulator:
      collectedData: {}
      handles: {}
      handlers: {}
      successHandlers: {}
      errorHandlers: {}
      interval: 2000

    # Turns methods into accumulators, collecting calls and sending
    # them out in intervals
    # obj
    #   the object the methods are read from and written to
    # methods
    #   zero or more names (strings) of methods (object members) to be wrapped
    wrapAccumulators: (obj, methods) ->
      # Replace methods
      for name in methods
        func = obj[name]
        unless typeof func is 'function'
          throw new TypeError "utils.wrapAccumulators: method #{name} not found"
        # Replace method
        obj[name] = utils.createAccumulator name, obj[name], obj

      # Bind to unload to synchronously flush accumulated remains
      $(window).unload =>
        handler(async: false) for name, handler of utils.accumulator.handlers

    # Returns an accumulator for the given 'func' with the
    # parameter list (data, success, error, options)
    createAccumulator: (name, func, context) ->
      # Create a unique ID for the function, save it as a
      # property of the function object
      unless id = func.__uniqueID
        id = func.__uniqueID = name + String(Math.random()).replace('.', '')

      acc = utils.accumulator

      # Cleanup data
      cleanup = ->
        delete acc.collectedData[id]
        delete acc.successHandlers[id]
        delete acc.errorHandlers[id]

      # Create accumulated success and error callbacks

      accumulatedSuccess = ->
        handlers = acc.successHandlers[id]
        handler.apply(this, arguments) for handler in handlers if handlers
        cleanup()

      accumulatedError = ->
        handlers = acc.errorHandlers[id]
        handler.apply(this, arguments) for handler in handlers if handlers
        cleanup()

      # Resulting function
      (data, success, error, rest...) ->
        # Store data, success and error handlers
        if data
          acc.collectedData[id] = (acc.collectedData[id] or []).concat(data)
        if success
          acc.successHandlers[id] = (
            acc.successHandlers[id] or []
          ).concat(success)
        if error
          acc.errorHandlers[id] = (acc.errorHandlers[id] or []).concat(error)

        # Set timeout if not already set
        return if acc.handles[id]

        handler = (options = options) ->
          return unless collectedData = acc.collectedData[id]
          # Call the original function
          args = [
            collectedData, accumulatedSuccess, accumulatedError
          ].concat(rest)
          func.apply context, args
          # Clear timeout
          clearTimeout acc.handles[id]
          # Remove handles and handlers
          delete acc.handles[id]
          delete acc.handlers[id]

        # Save the handler
        acc.handlers[id] = handler
        # Wrap handler in additional function to ignore
        # Firefox' latency arguments
        acc.handles[id] = setTimeout (-> handler()), acc.interval

    # Call the given function `func` when the global event `eventType` occurs.
    # Defaults to 'login', so the `func` is called when
    # the user has successfully logged in.
    # When the function is called, `this` points to the given `context`.
    # You may pass a `loginContext` for the UI context where
    # the login was triggered.
    afterLogin: (context, func, eventType = 'login', args...) ->
      if mediator.user
        # All fine, just pass through
        func.apply context, args
      else
        # Register a handler for the given event
        loginHandler = ->
          # Cleanup
          mediator.unsubscribe eventType, loginHandler
          # Pass to wrapped function
          func.apply context, args

        mediator.subscribe eventType, loginHandler

    deferMethodsUntilLogin: (obj, methods, eventType = 'login') ->
      methods = [methods] if typeof methods is 'string'

      for name in methods
        func = obj[name]
        unless typeof func is 'function'
          throw new TypeError "utils.deferMethodsUntilLogin: method #{name} 
not found"
        obj[name] = _(utils.afterLogin).bind null, obj, func, eventType

    # Delegates to afterLogin, but triggers the login dialog if the user
    # isn't logged in
    # and calls preventDefault if an event object is passed.
    ensureLogin: (context, func, loginContext, eventType = 'login', args...) ->
      utils.afterLogin context, func, eventType, args...

      unless mediator.user
        # If an event is passed to the original function, prevent the
        # default action
        if (e = args[0]) and typeof e.preventDefault is 'function'
          e.preventDefault()

        # Start login process
        mediator.publish '!showLogin', loginContext

    # Wrap methods which need a logged-in user.
    # Trigger the login when they are called and there is no user.
    # Arguments:
    # `obj`: The object whose methods should be wrapped
    # `methods`: A string or an array of strings with method names
    # `loginContext`: object with login context information, should have
    #                 a `description` property
    # `eventType`: The global PubSub event the actual method call will wait for.
    #              Defaults to 'login'.
    ensureLoginForMethods: (obj, methods, loginContext, eventType = 'login') ->
      # Transform a single method string into a list
      methods = [methods] if typeof methods is 'string'

      for name in methods
        func = obj[name]
        unless typeof func is 'function'
          throw new TypeError "utils.ensureLoginForMethods: method #{name} 
not found"
        obj[name] = _(utils.ensureLogin).bind(
          null, obj, func, loginContext, eventType
        )

  # Seal the utils object
  Object.seal? utils

  # Return utils
  utils
