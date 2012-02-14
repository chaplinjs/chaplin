define ['lib/utils', 'lib/subscriber', 'lib/view_helper'], (utils, Subscriber) ->

  'use strict'

  class View extends Backbone.View

    # Mixin a Subscriber
    _(View.prototype).defaults Subscriber

    # View container element
    # Set this property in a derived class to specify the container element.
    # The view is automatically appended to the container element
    # when it’s rendered.
    containerSelector: null
    $container: null


    initialize: ->
      #console.debug 'View#initialize', @

      # Listen for disposal of the model
      # If the model is disposed, automatically dispose the associated view
      if @model or @collection
        @modelBind 'dispose', @dispose

      # Create a shortcut to the container element
      if @containerSelector
        @$container = $(@containerSelector)


    # Make delegateEvents defunct, it is not used in our approach
    # but is called by Backbone internally

    delegateEvents: ->


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
        console.trace()
        throw new TypeError 'View#delegate: only two or three arguments are allowed'

      throw new TypeError 'View#delegate: handler argument must be function' if typeof handler isnt 'function'

      # Add an event namespace
      eventType += ".delegate#{@cid}"

      # Bind the handler to the view
      handler = _(handler).bind(@)

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

      # If the model is a Deferred, add a helper function
      # to get the Deferred state
      if @model and typeof @model.state is 'function'
        templateData.resolved = =>
          @model.state() is 'resolved'

      templateData

    # Main render function
    # Always bind it to the view instance

    render: =>
      #console.debug "View#render", @, "\n\tel: #{@el}\n\tmodel: #{@model}\n\tdisposed: #{@disposed}"

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

      # Automatically append to DOM if the container element is set
      # TODO: Sometimes it’s better to do this at the end of a specific render method
      if @$container
        @$container.append @el

      # Return this
      @

    # Default event handler to prevent browser default
    preventDefault: (e) ->
      e.preventDefault() if e and e.preventDefault


    #
    # Disposal
    #

    disposed: false

    dispose: =>
      return if @disposed
      #console.debug 'View#dispose', @

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
      #console.debug 'View#dispose', @, 'finished'
      @disposed = true

      # Your're frozen when your heart’s not open
      Object.freeze? @
