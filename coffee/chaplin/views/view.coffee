define [
  'jquery',
  'underscore',
  'backbone',
  'chaplin/lib/utils',
  'chaplin/lib/subscriber',
  'chaplin/models/model'
], ($, _, Backbone, utils, Subscriber, Model) ->
  'use strict'

  class View extends Backbone.View

    # Mixin a Subscriber
    _(@prototype).extend Subscriber

    # Automatic rendering
    # -------------------

    # Flag whether to render the view automatically on initialization.
    # As an alternative you might pass a `render` option to the constructor.
    autoRender: false

    # Automatic inserting into DOM
    # ----------------------------

    # View container element
    # Set this property in a derived class to specify the container element.
    # Normally this is a selector string but it might also be an element or
    # jQuery object.
    # The view is automatically inserted into the container when it’s rendered.
    # As an alternative you might pass a `container` option to the constructor.
    container: null

    # Method which is used for adding the view to the DOM
    # Like jQuery’s `html`, `prepend`, `append`, `after`, `before` etc.
    containerMethod: 'append'

    # Subviews
    # --------

    # List of subviews
    subviews: null
    subviewsByName: null
    
    # Method wrapping to enable `afterRender` and `afterInitialize`
    # -------------------------------------------------------------
    
    # Wrap a method in order to call the corresponding
    # `after-` method automatically
    wrapMethod: (name) ->
      instance = this
      # Enclose the original function
      func = instance[name]
      # Set a flag
      instance["#{name}IsWrapped"] = true
      # Create the wrapper method
      instance[name] = ->
        # Call the original method
        func.apply instance, arguments
        # Call the corresponding `after-` method
        instance["after#{utils.upcase(name)}"] arguments...

    constructor: ->
      # Wrap `initialize` so `afterInitialize` is called afterwards
      # Only wrap if there is an overring method, otherwise we
      # can call the `after-` method directly
      unless @initialize is View::initialize
        @wrapMethod 'initialize'

      # Wrap `render` so `afterRender` is called afterwards
      unless @render is View::render
        @wrapMethod 'render'
      else
        # Otherwise just bind the `render` method
        @render = _(@render).bind this

      # Call Backbone’s constructor
      super

    initialize: (options) ->
      ###console.debug 'ChaplinView#initialize', this, 'options', options###
      # No super call here, Backbone’s `initialize` is a no-op

      # Copy some options to instance properties
      if options
        for prop in ['autoRender', 'container', 'containerMethod']
          if options[prop]?
            @[prop] = options[prop]

      # Initialize subviews
      @subviews = []
      @subviewsByName = {}

      # Listen for disposal of the model
      # If the model is disposed, automatically dispose the associated view
      if @model or @collection
        @modelBind 'dispose', @dispose

      # Call `afterInitialize` if `initialize` was not wrapped
      unless @initializeIsWrapped
        @afterInitialize()

    # This method is called after a specific `initialize` of a derived class
    afterInitialize: ->
      # Render automatically if set by options or instance property
      @render() if @autoRender

    # User input event handling
    # -------------------------

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
        throw new TypeError 'ChaplinView#delegate: first argument must be a string'

      if arguments.length is 2
        handler = second
      else if arguments.length is 3
        selector = second
        if typeof selector isnt 'string'
          throw new TypeError 'ChaplinView#delegate: ' +
            'second argument must be a string'
        handler = third
      else
        throw new TypeError 'ChaplinView#delegate: ' +
          'only two or three arguments are allowed'

      if typeof handler isnt 'function'
        throw new TypeError 'ChaplinView#delegate: ' +
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
        throw new TypeError 'ChaplinView#modelBind: ' +
          'type must be a string'
      if typeof handler isnt 'function'
        throw new TypeError 'ChaplinView#modelBind: ' +
          'handler argument must be function'

      # Get model/collection reference
      model = @model or @collection
      unless model
        throw new TypeError 'ChaplinView#modelBind: no model or collection set'

      # Ensure that a handler isn’t registered twice
      model.off type, handler, this

      # Register model handler, force context to the view
      model.on type, handler, this

    # Unbind from a model event

    modelUnbind: (type, handler) ->
      if typeof type isnt 'string'
        throw new TypeError 'ChaplinView#modelUnbind: ' +
          'type argument must be a string'
      if typeof handler isnt 'function'
        throw new TypeError 'ChaplinView#modelUnbind: ' +
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
      model.off null, null, this

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
      if name and view
        # Add the subview, ensure it’s unique
        @removeSubview name
        @subviews.push view
        @subviewsByName[name] = view
        view
      else if name
        # Get and return the subview by the given name
        @subviewsByName[name]

    # Removing a subview
    removeSubview: (nameOrView) ->
      return unless nameOrView

      if typeof nameOrView is 'string'
        # Name given, search for a subview by name
        name = nameOrView
        view = @subviewsByName[name]
      else
        # View instance given, search for the corresponding name
        view = nameOrView
        for otherName, otherView of @subviewsByName
          if view is otherView
            name = otherName
            break

      # Brak if no view and name were found
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
      serialize = (object) ->
        result = {}
        for key, value of object
          result[key] = if value instanceof Model
            serialize value.getAttributes()
          else
            value
        result

      modelAttributes = @model and @model.getAttributes()
      templateData = if modelAttributes
        # Return an object which delegates to the returned attributes
        # object so a custom getTemplateData might safely add and alter
        # properties (at least primitive values).
        utils.beget serialize modelAttributes
      else
        {}

      # If the model is a Deferred, add a flag to get the Deferred state
      if @model and typeof @model.state is 'function'
        templateData.resolved = @model.state() is 'resolved'

      templateData

    getTemplateFunction: ->
      # Chaplin doesn’t define how you load and compile templates in order to
      # render views. The example application uses Handlebars and RequireJS
      # to load and compile templates on the client side. See the derived
      # View class in the example application.
      throw new Error 'ChaplinView#getTemplateFunction must be overridden'

    # Main render function
    # This method is bound to the instance in the constructor (see above)
    render: ->
      ###console.debug 'ChaplinView#render', this###

      # Do not render if the object was disposed
      # (render might be called as an event handler which wasn’t
      # removed correctly)
      return if @disposed

      templateFunc = @getTemplateFunction()
      if typeof templateFunc is 'function'

        # Call the template function passing the template data
        html = templateFunc @getTemplateData()

        # Replace HTML
        # ------------

        # This is a workaround for an apparent issue with jQuery 1.7’s
        # innerShiv feature. Using @$el.html(html) caused issues with
        # HTML5-only tags in IE7 and IE8.
        @$el.empty().append html

      # Call `afterRender` if `render` was not wrapped
      @afterRender() unless @renderIsWrapped

      # Return the view
      this

    # This method is called after a specific `render` of a derived class
    afterRender: ->
      # Automatically append to DOM if the container element is set
      if @container
        # Append the view to the DOM
        $(@container)[@containerMethod] @el
        # Trigger an event
        @trigger 'addedToDOM'

      # Return the view
      this

    # Disposal
    # --------

    disposed: false

    dispose: ->
      ###console.debug 'ChaplinView#dispose', this, 'disposed?', @disposed###
      return if @disposed

      # Dispose subviews
      view.dispose() for view in @subviews

      # Unbind handlers of global events
      @unsubscribeAllEvents()

      # Unbind all model handlers
      @modelUnbindAll()

      # Remove all event handlers on this module
      @off()

      # Remove the topmost element from DOM. This also removes all event
      # handlers from the element and all its children.
      @$el.remove()

      # Remove element references, options,
      # model/collection references and subview lists
      properties = [
        'el', '$el',
        'options', 'model', 'collection',
        'subviews', 'subviewsByName',
        '_callbacks'
      ]
      delete this[prop] for prop in properties

      # Finished
      @disposed = true

      # Your're frozen when your heart’s not open
      Object.freeze? this
