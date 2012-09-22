define [
  'jquery'
  'underscore'
  'backbone'
  'chaplin/lib/utils'
  'chaplin/lib/event_broker'
  'chaplin/models/model'
], ($, _, Backbone, utils, EventBroker, Model) ->
  'use strict'

  class View extends Backbone.View

    # Mixin an EventBroker
    _(@prototype).extend EventBroker

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
        # Stop if the view was already disposed
        return false if @disposed
        # Call the original method
        func.apply instance, arguments
        # Call the corresponding `after-` method
        instance["after#{utils.upcase(name)}"] arguments...
        # Return the view
        instance

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

      # Return the bound handler
      handler

    # Remove all handlers registered with @delegate

    undelegate: ->
      @$el.unbind ".delegate#{@cid}"

    # Model binding
    # The following implementation resembles EventBroker
    # --------------------------------------------------

    # Bind to a model event
    modelBind: (type, handler) ->
      if typeof type isnt 'string'
        throw new TypeError 'View#modelBind: ' +
          'type must be a string'
      if typeof handler isnt 'function'
        throw new TypeError 'View#modelBind: ' +
          'handler argument must be function'

      # Get model/collection reference
      modelOrCollection = @model or @collection
      unless modelOrCollection
        throw new TypeError 'View#modelBind: no model or collection set'

      # Ensure that a handler isn’t registered twice
      modelOrCollection.off type, handler, this

      # Register model handler, force context to the view
      modelOrCollection.on type, handler, this

    # Unbind from a model event

    modelUnbind: (type, handler) ->
      if typeof type isnt 'string'
        throw new TypeError 'View#modelUnbind: ' +
          'type argument must be a string'
      if typeof handler isnt 'function'
        throw new TypeError 'View#modelUnbind: ' +
          'handler argument must be a function'

      # Get model/collection reference
      modelOrCollection = @model or @collection
      return unless modelOrCollection

      # Remove model handler
      modelOrCollection.off type, handler

    # Unbind all recorded model event handlers
    modelUnbindAll: ->
      # Get model/collection reference
      modelOrCollection = @model or @collection
      return unless modelOrCollection

      # Remove all handlers with a context of this view
      modelOrCollection.off null, null, this

    # Setup a simple one-way model-view binding
    # Pass changed attribute values to specific elements in the view
    # For form controls, the value is changed, otherwise the element
    # text content is set to the model attribute value.
    # Example: @pass 'attribute', '.selector'
    pass: (attribute, selector) ->
      @modelBind "change:#{attribute}", (model, value) =>
        $el = @$(selector)
        if $el.is('input, textarea, select, button')
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

      # Break if no view and name were found
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

    # Get the model/collection data for the templating function
    getTemplateData: ->
      if @model
        # Serialize the model
        templateData = @model.serialize()
      else if @collection
        # Collection: Serialize all models
        items = []
        for model in @collection.models
          items.push model.serialize()
        templateData = {items}
      else
        # Empty object
        templateData = {}

      modelOrCollection = @model or @collection
      if modelOrCollection

        # If the model/collection is a Deferred, add a `resolved` flag,
        # but only if it’s not present yet
        if typeof modelOrCollection.state is 'function' and
          not ('resolved' of templateData)
            templateData.resolved = modelOrCollection.state() is 'resolved'

        # If the model/collection is a SyncMachine, add a `synced` flag,
        # but only if it’s not present yet
        if typeof modelOrCollection.isSynced is 'function' and
          not ('synced' of templateData)
            templateData.synced = modelOrCollection.isSynced()

      templateData

    # Returns the compiled template function
    getTemplateFunction: ->
      # Chaplin doesn’t define how you load and compile templates in order to
      # render views. The example application uses Handlebars and RequireJS
      # to load and compile templates on the client side. See the derived
      # View class in the example application:
      # https://github.com/chaplinjs/facebook-example/blob/master/coffee/views/base/view.coffee
      #
      # If you precompile templates to JavaScript functions on the server,
      # you might just return a reference to that function.
      # Several precompilers create a global `JST` hash which stores the
      # template functions. You can get the function by the template name:
      # JST[@templateName]

      throw new Error 'View#getTemplateFunction must be overridden'

    # Main render function
    # This method is bound to the instance in the constructor (see above)
    render: ->
      # Do not render if the object was disposed
      # (render might be called as an event handler which wasn’t
      # removed correctly)
      return false if @disposed

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

    # Disposal
    # --------

    disposed: false

    dispose: ->
      return if @disposed

      # Dispose subviews
      subview.dispose() for subview in @subviews

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

      # You’re frozen when your heart’s not open
      Object.freeze? this
