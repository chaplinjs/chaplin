define [
  'chaplin/lib/utils', 'chaplin/lib/subscriber',
  'chaplin/lib/view_helper' # Just load the file, no return value
], (utils, Subscriber) ->
  'use strict'

  class View extends Backbone.View

    # Mixin a Subscriber
    _(View.prototype).extend Subscriber

    # Automatic rendering
    # -------------------

    # Flag whether to render the view automatically on initialization.
    # As an alternative you might pass a `render` option to the constructor.
    autoRender: false

    # Automatic inserting into DOM
    # ----------------------------

    # View container element
    # Set this property in a derived class to specify to selector
    # of the container element. The view is automatically inserted
    # into the container when it’s rendered.
    # As an alternative you might pass a `container` option to the constructor.
    containerSelector: null

    # Method which is used for adding the view to the DOM
    # Like jQuery’s `html`, `prepend`, `append`, `after`, `before` etc.
    containerMethod: 'append'

    # Store the container element reference
    $container: null

    # Subviews
    # --------

    # List of subviews
    subviews: null
    subviewsByName: null

    constructor: ->
      #console.debug 'View#constructor', this

      # Wrap `initialize` and `render` in order to call `afterInitialize`
      # and `afterRender`
      wrapMethod = (name) =>
        # TODO: This isn’t so nice because it creates wrappers on each
        # instance which leads to many function objects.
        # A better way would be using Object.getPrototypeOf to look for a
        # prototype in the chain which has an overriding method.
        # For now, get the method using the prototype chain and
        # wrap it on the instance.
        func = this[name]
        # Create a method on the instance which wraps the inherited
        this[name] = =>
          #console.debug 'View#' + name + ' wrapper', this
          # Call the original method
          func.apply this, arguments
          # Call the corresponding `after~` method
          this["after#{utils.upcase(name)}"].apply this, arguments

      wrapMethod 'initialize'
      wrapMethod 'render'

      # Finally call Backbone’s constructor
      super

    initialize: (options) ->
      #console.debug 'View#initialize', this, 'options', options
      # No super call here, Backbone’s `initialize` is a no-op

      # Initialize subviews
      @subviews = []
      @subviewsByName = {}

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

    # User input event handling
    # -------------------------

    # Make delegateEvents defunct, it is not used in our approach
    # but is called by Backbone internally. Please use `delegate` and
    # `undelegate` (see below) instead of the `events` hash.
    delegateEvents: ->
      # Noop

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
      if typeof eventType isnt 'string'
        throw new TypeError 'View#delegate: first argument must be a string'

      if arguments.length is 2
        handler = second
      else if arguments.length is 3
        selector = second
        if typeof selector isnt 'string'
          throw new TypeError 'View#delegate: second argument must be a string'
        handler = third
      else
        throw new TypeError 'View#delegate: only two or three arguments are
allowed'

      if typeof handler isnt 'function'
        throw new TypeError 'View#delegate: handler argument must be function'

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

    # Model binding
    # The following implementation resembles subscriber.coffee
    # --------------------------------------------------------

    # The handler store
    _modelBindings: null

    # Bind to a model event
    modelBind: (type, handler) ->
      if typeof type isnt 'string'
        throw new TypeError 'View#modelBind: type must be string'
      if typeof handler isnt 'function'
        throw new TypeError 'View#modelBind: handler must be function'

      # Get model/collection reference
      model = @model or @collection
      unless model
        throw new TypeError 'View#modelBind: no model or collection set'

      # Add to store
      @_modelBindings or= {}
      handlers = @_modelBindings[type] or= []
      # Ensure that a handler isn’t registered twice
      return if _(handlers).include handler
      handlers.push handler

      # Register model handler, force context to the view
      model.on type, handler, @

    # Unbind from a model event

    modelUnbind: (type, handler) ->
      if typeof type isnt 'string'
        throw new TypeError 'View#modelUnbind: type must be string'
      if typeof handler isnt 'function'
        throw new TypeError 'View#modelUnbind: handler must be function'

      # Remove from store
      return unless @_modelBindings
      handlers = @_modelBindings[type]
      if handlers
        index = _(handlers).indexOf handler
        handlers.splice index, 1 if index > -1
        delete @_modelBindings[type] if handlers.length is 0

      # Get model/collection reference
      model = @model or @collection
      return unless model

      # Remove model handler
      model.off type, handler

    # Unbind all recorded model event handlers
    modelUnbindAll: () ->
      # Clear store
      @_modelBindings = null

      # Remove all handlers with a context of this view
      model = @model or @collection
      return unless model
      model.off null, null, @

    # Setup a simple one-way model-view binding
    # Pass changed values from model to specific elements in the view
    pass: (eventType, selector) ->
      model = @model or @collection
      @modelBind eventType, (model, val) =>
        @$(selector).html(val)

    # Subviews
    # --------

    # Getting or adding a subview
    subview: (name, view) ->
      #console.debug 'View#subview', name, view
      if name and view
        @removeSubview name
        @subviews.push view
        @subviewsByName[name] = view
        #console.debug '\tadd', name, view
        view
      else if name
        #console.debug '\tget', name
        @subviewsByName[name]

    # Removing a subview
    removeSubview: (nameOrView) ->
      #console.debug 'View#removeSubview nameOrView:', nameOrView
      return unless nameOrView

      if typeof nameOrView is 'string'
        name = nameOrView
        view = @subviewsByName[name]
      else
        view = nameOrView
        # Search for the name of the view
        for otherName, otherView of @subviewsByName
          if view is otherView
            name = otherName
            break

      #console.debug 'View#removeSubview found name:', name, 'view:', view
      return unless name and view and view.dispose

      # Dispose the view
      view.dispose()

      # Remove the subview from the lists
      index = _(@subviews).indexOf(view)
      if index > -1
        @subviews.splice index, 1
      delete @subviewsByName[name]

    # Rendering
    # ---------

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

      # In the end, you might want to precompile the templates to JavaScript
      # functions on the server-side and just load the JavaScript code.
      # Several precompilers create a global JST hash which stores the
      # template functions. You can get the function by the template name:
      #
      # templateFunc = JST[@template]
      #
      # In this demo, we load the template as a string, compile it
      # on the client-side and store it on the view constructor as a
      # static property.

      template = @template

      if typeof template is 'string'
        template = Handlebars.compile template
        # Save compiled template
        @template = template

      if typeof template is 'function'

        # Call the template function passing the template data
        html = template @getTemplateData()

        # Replace HTML
        # This is a workaround for an apparent issue with jQuery 1.7’s
        # innerShiv feature. Using @$el.html(html) caused issues with
        # HTML5-only tags in IE7 and IE8
        @$el.empty().append html

      # Return this
      this

    # This method is called after a specific `render` of a derived class

    afterRender: ->
      #console.debug 'View#afterRender', this

      # Automatically append to DOM if the container element is set
      if @$container and @$container[@containerMethod]?
        #console.debug '\tappend to DOM'
        @$container[@containerMethod] @el
        # Trigger an event
        @trigger 'addedToDOM'

      # Return this
      this

    # Disposal
    # --------

    disposed: false

    dispose: =>
      return if @disposed
      #console.debug 'View#dispose', this

      # Dispose subviews
      view.dispose() for view in @subviews

      # Unbind handlers of global events
      @unsubscribeAllEvents()

      # Unbind all model handlers
      @modelUnbindAll()

      # Remove all event handlers
      @off()

      # Remove the topmost element from DOM. This also removes all event
      # handlers from the element and all its children.
      @$el.remove()

      # Remove element references, options and model/collection references
      properties = [
        'el', '$el', '$container', 'options', 'model', 'collection',
        'subviews', 'subviewsByName'
      ]
      delete this[prop] for prop in properties

      # Finished
      #console.debug 'View#dispose', this, 'finished'
      @disposed = true

      # Your're frozen when your heart’s not open
      Object.freeze? this
