define [
  'jquery',
  'underscore',
  'backbone',
  'handlebars',
  'chaplin/lib/utils',
  'chaplin/lib/subscriber',
  'chaplin/lib/view_helper' # Just load the file, no return value
], ($, _, Backbone, Handlebars, utils, Subscriber) ->
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

    # Subviews
    # --------

    # List of subviews
    subviews: null
    subviewsByName: null

    # Wrap a `method` in order to call and `afterMethod`
    wrapMethod = (obj, name) ->
      func = obj[name]
      #console.debug 'View wrapMethod', obj, name
      # Create a method on the instance which wraps the inherited
      obj[name] = ->
        #console.debug 'View#' + name + ' wrapper', obj
        # Call the original method
        func.apply obj, arguments
        # Call the corresponding `after-` method
        obj["after#{utils.upcase(name)}"].apply obj, arguments

    constructor: ->
      #console.debug 'View#constructor', this

      # Wrap `initialize` so `afterInitialize` is called afterwards
      # Only wrap if there is an overring method, otherwise we
      # call the after method directly
      unless @initialize is View.prototype.initialize
        wrapMethod this, 'initialize'

      # Wrap `render` so `afterRender` is called afterwards
      unless @initialize is View.prototype.initialize
        wrapMethod this, 'render'
      else
        # Otherwise just bind the `render` method normally
        @render = _(@render).bind this

      # Call Backbone’s constructor
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

      # Call afterInitialize manually when initialize wasn’t wrapped
      if @initialize is View.prototype.initialize
        #console.debug '\tcall afterInitialize without wrapping'
        @afterInitialize()

    # This method is called after a specific `initialize` of a derived class
    afterInitialize: ->
      #console.debug 'View#afterInitialize', this

      # Render automatically if set by options or instance property
      # `autoRender` option may override `autoRender` instance property
      autoRender = if @options.autoRender?
          @options.autoRender
        else
          @autoRender
      @render() if autoRender

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
          throw new TypeError 'View#delegate: ' +
            'second argument must be a string'
        handler = third
      else
        throw new TypeError 'View#delegate: ' +
          'only two or three arguments are allowed'

      if typeof handler isnt 'function'
        throw new TypeError 'View#delegate: ' +
          'handler argument must be function'

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

    # Bind to a model event
    modelBind: (type, handler) ->
      if typeof type isnt 'string'
        throw new TypeError 'View#modelBind: ' +
          'type must be a string'
      if typeof handler isnt 'function'
        throw new TypeError 'View#modelBind: ' +
          'handler argument must be function'

      # Get model/collection reference
      model = @model or @collection
      unless model
        throw new TypeError 'View#modelBind: no model or collection set'

      # Ensure that a handler isn’t registered twice
      model.off type, handler, @

      # Register model handler, force context to the view
      model.on type, handler, @

    # Unbind from a model event

    modelUnbind: (type, handler) ->
      if typeof type isnt 'string'
        throw new TypeError 'View#modelUnbind: ' +
          'type argument must be a string'
      if typeof handler isnt 'function'
        throw new TypeError 'View#modelUnbind: ' +
          'handler argument must be a function'

      # Get model/collection reference
      model = @model or @collection
      return unless model

      # Remove model handler
      model.off type, handler

    # Unbind all recorded model event handlers
    modelUnbindAll: () ->
      # Get model/collection reference
      model = @model or @collection
      return unless model

      # Remove all handlers with a context of this view
      model.off null, null, @

    # Setup a simple one-way model-view binding
    # Pass changed attribute values to specific elements in the view
    # For form controls, the value is changed, otherwise the element
    # text content is set to the model attribute value.
    # Example: @pass 'attribute', '.selector'
    pass: (attribute, selector) ->
      @modelBind "change:#{attribute}", (model, value) =>
        $el = @$(selector)
        if $el.is(':input')
          $el.val value
        else
          $el.text value

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
    render: ->
      #console.debug "View#render\n\t", this, "\n\tel:", @el, "\n\tmodel/collection:", (@model or @collection), "\n\tdisposed:", @disposed

      return if @disposed

      # Template compilation
      # --------------------

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
        # ------------

        # This is a workaround for an apparent issue with jQuery 1.7’s
        # innerShiv feature. Using @$el.html(html) caused issues with
        # HTML5-only tags in IE7 and IE8
        @$el.empty().append html

      # Return this
      this

    # This method is called after a specific `render` of a derived class
    afterRender: ->
      #console.debug 'View#afterRender', this

      # Create a shortcut to the container element
      # The view will be automatically appended to the container when rendered
      # `container` option may override `autoRender` instance property
      container = if @options.container?
          @options.container
        else
          @containerSelector

      # Automatically append to DOM if the container element is set
      if container
        # Get the attach method name
        containerMethod = if @options.containerMethod?
            @options.containerMethod
          else
            @containerMethod

        #console.debug '\tappend to DOM', containerMethod, container
        $(container)[containerMethod] @el

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
        'el', '$el',
        'options', 'model', 'collection',
        'subviews', 'subviewsByName'
      ]
      delete this[prop] for prop in properties

      # Finished
      #console.debug 'View#dispose', this, 'finished'
      @disposed = true

      # Your're frozen when your heart’s not open
      Object.freeze? this
