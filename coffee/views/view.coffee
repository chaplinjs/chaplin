define ['lib/utils', 'lib/subscriber', 'lib/view_helper'], (utils, Subscriber) ->

  'use strict'

  class View extends Backbone.View

    # Mixin a Subscriber
    _(View.prototype).defaults Subscriber

    # Automatic rendering
    # Flag whether to render the view automatically on initialization.
    # As an alternative you might pass a `render` option to the constructor.
    autoRender: false

    # Automatic appending to DOM
    # View container element
    # Set this property in a derived class to specify to selector
    # of the container element. The view is automatically appended
    # to the container when it’s rendered.
    # As an alternative you might pass a `container` option to the constructor.
    containerSelector: null
    $container: null


    constructor: ->
      #console.debug 'View#constructor', this

      # Wrap `initialize` and `render` in order to call `afterInitialize` and `afterRender`
      instance = this
      wrapMethod = (name) ->
        # TODO: This isn’t so nice because it creates wrappers on each
        # instance which leads to many function objects.
        # A better way would be using Object.getPrototypeOf to look for a
        # prototype in the chain which has a overriding method.
        # For now, get the method using the prototype chain and
        # wrap it on the instance.
        func = instance[name]
        # Create a method on the instance which wraps the inherited
        instance[name] = ->
          #console.debug 'View#' + name + ' wrapper', this
          # Call the original method
          func.apply instance, arguments
          # Call the corresponding `after~` method
          instance["after#{utils.upcase(name)}"].apply instance, arguments

      wrapMethod 'initialize'
      wrapMethod 'render'

      # Finally call Backbone’s constructor
      super


    initialize: (options) ->
      #console.debug 'View#initialize', this, 'options', options
      # No super call here, Backbone’s `initialize` is a no-op

      # Listen for disposal of the model
      # If the model is disposed, automatically dispose the associated view
      if @model or @collection
        @modelBind 'dispose', @dispose

      # Create a shortcut to the container element
      # The view will be automatically appended to the container when rendered
      if options and options.container
        @$container = $(container)
      else if @containerSelector
        @$container = $(@containerSelector)

    # This method is called after a specific `initialize` of a derived class

    afterInitialize: (options) ->
      #console.debug 'View#afterInitialize', this, 'options', options

      # Render automatically if set by options or instance property
      # and the option do not override it
      byOption = options and options.autoRender is true
      byDefault = @autoRender and not byOption
      @render() if byOption or byDefault


    # Make delegateEvents defunct, it is not used in our approach
    # but is called by Backbone internally

    delegateEvents: ->
      # Noop

    # Setup a simple one-way model-view binding
    # Pass changed values from model to specific elements in the view

    pass: (eventType, selector) ->
      model = @model or @collection
      @modelBind eventType, (model, val) =>
        @$(selector).html(val)


    #
    # User input event handling
    #

    # Event handling using event delegation
    # Register a handler for a specific event type
    # For the whole view:
    #   delegate(eventType, handler)
    #   e.g.
    #   @delegate('click', @clicked)
    # For an element in the passing a selector:
    #   delegate(eventType, selector, handler)
    #   e.g.
    #   @delegate('click', 'button.confirm', @confirm)

    delegate: (eventType, second, third) ->

      throw new TypeError 'View#delegate: first argument must be a string' if typeof eventType isnt 'string'

      if arguments.length is 2
        handler = second
      else if arguments.length is 3
        selector = second
        throw new TypeError 'View#delegate: second argument must be a string' if typeof selector isnt 'string'
        handler = third
      else
        throw new TypeError 'View#delegate: only two or three arguments are allowed'

      throw new TypeError 'View#delegate: handler argument must be function' if typeof handler isnt 'function'

      # Add an event namespace
      eventType += ".delegate#{@cid}"

      # Bind the handler to the view
      handler = _(handler).bind(this)

      if selector
        # Register handler
        @$el.on eventType, selector, handler
      else
        # Register handler
        @$el.on eventType, handler

    # Remove all handlers registered with @delegate

    undelegate: ->
      @$el.unbind ".delegate#{@cid}"


    #
    # Model binding
    #

    # The following implementation resembles subscriber.coffee

    # Bind to a model event

    modelBind: (type, handler) ->
      if typeof type isnt 'string'
        throw new TypeError 'View#modelBind: type argument must be string'
      if typeof handler isnt 'function'
        throw new TypeError 'View#modelBind: handler argument must be function'
      model = @model or @collection
      return unless model
      @modelBindings or= {}
      handlers = @modelBindings[type] or= []
      return if _(handlers).include handler
      handlers.push handler
      model.bind type, handler

    # Unbind from a model event

    modelUnbind: (type, handler) ->
      if typeof type isnt 'string'
        throw new TypeError 'View#modelUnbind: type argument must be string'
      if typeof handler isnt 'function'
        throw new TypeError 'View#modelUnbind: handler argument must be function'
      return unless @modelBindings
      handlers = @modelBindings[type]
      if handlers
        index = _(handlers).indexOf handler
        handlers.splice index, 1 if index > -1
        delete @modelBindings[type] if handlers.length is 0
      model = @model or @collection
      return unless model
      model.unbind type, handler

    # Unbind all recorded global handlers

    modelUnbindAll: () ->
      return unless @modelBindings
      model = @model or @collection
      return unless model
      for own type, handlers of @modelBindings
        for handler in handlers
          model.unbind type, handler
      @modelBindings = null


    #
    # Rendering
    #

    # Get attributes from model or collection

    getTemplateData: ->

      modelAttributes = @model and @model.getAttributes()
      templateData = if modelAttributes
        # Return an object which delegates to the returned attributes
        # object so a custom getTemplateData might safely add and alter
        # properties (at least primitive values).
        utils.beget modelAttributes
      else
        {}

      # If the model is a Deferred, add a flag to get the Deferred state
      if @model and typeof @model.state is 'function'
        templateData.resolved = @model.state() is 'resolved'

      templateData

    # Main render function
    # Always bind it to the view instance

    render: =>
      #console.debug "View#render\n\t", this, "\n\tel:", @el, "\n\tmodel/collection:", (@model or @collection), "\n\tdisposed:", @disposed

      return if @disposed

      # Template compilation

      # In the end, you will want to precompile the templates to JavaScript functions
      # on the server-side and just load the compiled JavaScript code.
      # In this demo, we load the template as a string, compile it on the client-side
      # and store it on the view constructor as a static property.

      template = @constructor.template
      #console.debug "\ttemplate: #{typeof template}"

      if typeof template is 'string'
        template = Handlebars.compile template
        # Save compiled template
        @constructor.template = template

      if typeof template is 'function'

        # Call the template function passing the template data
        html = template @getTemplateData()

        # Replace HTML
        # This is a workaround for an apparent issue with jQuery 1.7’s innerShiv feature
        # Using @$el.html(html) caused issues with HTML5-only tags in IE7 and IE8
        @$el.empty().append html

      # Return this
      this

    # This method is called after a specific `render` of a derived class

    afterRender: ->
      #console.debug 'View#afterRender', this

      # Automatically append to DOM if the container element is set
      if @$container
        #console.debug '\tappend to DOM'
        @$container.append @el
        # Trigger an event
        @trigger 'addedToDOM'

      # Return this
      this


    # Default event handler to prevent browser default
    preventDefault: (e) ->
      e.preventDefault() if e and e.preventDefault


    #
    # Disposal
    #

    disposed: false

    dispose: =>
      return if @disposed
      #console.debug 'View#dispose', this

      # Unbind all model handlers
      @modelUnbindAll()

      # Unbind handlers of global events
      @unsubscribeAllEvents()

      # Remove the topmost element from DOM. This also removes all event handlers from
      # the element and all its children.
      @$el.remove()

      # Remove element references, options, model/collection references and event handlers
      properties = 'el $el $container options model collection _callbacks'.split(' ')
      delete @[prop] for prop in properties

      # Finished
      #console.debug 'View#dispose', this, 'finished'
      @disposed = true

      # Your're frozen when your heart’s not open
      Object.freeze? this
