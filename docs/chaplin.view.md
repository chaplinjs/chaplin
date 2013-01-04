# Chaplin.View

Chaplin’s `View` class is a highly extended and adapted Backbone `View`. All views should inherit from this class to avoid repetition.

Views may subscribe to Publish/Subscribe and model/collection events in a manner which allows proper disposal. They have a standard `render` method which renders a template into the view’s root element (`@el`).

The templating function is provided by `getTemplateFunction`. The input data for the template is provided by `getTemplateData`. By default, this method just returns an object which delegates to the model attributes. Views might override the method to process the raw model data for the view.

In addition to Backbone’s `events` hash and the `delegateEvents` method, Chaplin has the `delegate` method to register user input handlers. The declarative `events` hash doesn’t work well for class hierarchies when several `initialize` methods register their own handlers. The programatic approach of `delegate` solves these problems.

Also, `@model.bind()` should not be used directly. Chaplin has `@modelBind()` which forces the handler context so the handler can be removed automatically on view disposal. When using Backbone’s naked `bind`, you have to deregister the handler manually to clear the reference from the model to the view.


## Features und purpose

- Rendering model data using templates in a conventional way
- Robust and memory-safe model binding
- Automatic rendering and appending to the DOM
- Creating subviews
- Disposal which cleans up all subviews, model bindings and Pub/Sub events

<a id="initialize"></a>
### initialize(options)
* **options (default: empty hash)**
    * `autoRender` see [autoRender](#autoRender)
    * `container` see [container](#container)
    * `containerMethod` see [containerMethod](#containerMethod)
    * all standard [Backbone constructor
  options](http://backbonejs.org/#View-constructor) (`model`, `collection`,
  `el`, `id`, `className`, `tagName` and `attributes`)

  `options` may be specific on the view class or passed to the constructor. Passing
  in options during instantiation overrides the View prototype's defaults.

  Views must always call `super` from their `initialize` methods. Unlike
  Backbone's initialize method, Chaplin's initialize is required to
  create the instance's subviews and listen for model or collection disposal.

<a id="rendering"></a>
## Rendering: getTemplateFunction, render, …

  Your application should provide a standard way of rendering DOM
  nodes by creating HTML from templates and template data. Chaplin
  provides `getTemplateFunction` and `getTemplateData` for this purpose.
  
  Set [`autorender`](#autoRender) to true to enable rendering upon
  View instantiation. Will automatically append to a [`container`](#container)
  if one is set, although the method of appending can be overriden
  by setting the [`containerMethod`](#containerMethod) property
  (to `html`, `before`, `prepend`, etc).

<a id="getTemplateFunction"></a>
### getTemplateFunction()
* **function (throws error if not overriden)**

  Core method that returns the compiled template function. Usually
  set application-wide in a base view class.

  A common implementation will take a passed in `template` string and return
  a compiled template function (e.g. a Handlebars or Underscore template function).
```coffeescript
@template = require 'templates/comment_view'
```
or if using templates in the DOM
```coffeescript
@template = $('#comment_view_template').html()
```

if using Handlebars
```coffeescript
getTemplateFunction: ->
  Handlebars.compile @template
```
or if using underscore templates
```coffeescript
getTemplateFunction: ->
  _.template @template
```

  Packages like [Brunch With Chaplin](https://github.com/paulmillr/brunch-with-chaplin)
  precompile the template functions to improve application performance


<a id="getTemplateData"></a>
### getTemplateData()
* **function that returns Object (throws error if not overriden)**

  Empty method which returns the prepared model data for the template. Should
  be overriden by inheriting classes (often from model data).

```coffeescript
getTemplateData: ->
  @model.attributes

...

getTemplateData: ->
  title: 'Winnetou'
  author: 'Karl May'

```

  often overriden in a base model class to intelligently pick out attributes

<a id="render"></a>
### render
  By default calls the `templateFunction` with the `templateData` and sets the html
  of the `$el`. Can be overriden in your base view if needed, though should be
  suitable for the majority of cases.

<a id="afterInitialize"></a>
<a id="afterRender"></a>
## afterInitialize and afterRender
  Chaplin's utils provides a `wrapMethod` feature that facilitates creating complex
  class heirarchies. In the default implementation, only `initialize` and `render` are
  wrapped, giving the View `afterInitialize` and `afterRender` methods that are called
  after the prototype chain has completed for their respective heirarchy.
  
  `afterInitialize` calls `render` if `autoRender` is true, and `afterRender` attaches
  the View to its `container` element.

<a id="DOM-options"></a>
## Options for auto-rendering and DOM appending

<a id="autoRender"></a>
### autoRender
* **Boolean, default: false**
  
  Specifies whether the the View's `render` method should be called when
  a view is instantiated.

<a id="container"></a>
### container
* **jQuery object, selector string, or element, default: null**
  
  A selector for the View's containg element into which the `$el`
  will be rendered. The container must exist in the DOM.
  
  Set this property in a derived class to specify the container element.
  Normally this is a selector string but it might also be an element or
  jQuery object. View is automatically inserted into the container when
  it’s rendered (in the `afterRender` method). As an alternative you
  might pass a `container` option to the constructor.
  
  A container is often an empty element within a parent view.

<a id="containerMethod"></a>
### containerMethod
* **String, jQuery object method (default: 'append')**
  
  Method which is used for adding the view to the DOM via the `container`
  element. (Like jQuery’s `html`, `prepend`, `append`, `after`, `before` etc.)
  
## Event delegation
<a id="delegate"></a>
### delegate(eventType, [selector], handler)
* **String eventType - jQuery DOM event, (e.g. 'click', 'focus', etc )**,
* **String selector (optional, if not set will bind to the view's $el)**,
* **function handler (automatically bound to `this`)**

Backbone's `events` hash doesn't work well with inheritance, so
Chaplin provides the `delegate` method for this purpose. `delegate`
is a wrapper for jQuery's `@$el.on` method, and has the same
method signature.

```coffeescript
# For events affecting the whole view:
# delegate(eventType, handler)
@delegate('click', @clicked)

# For events only affecting an element or colletion of elements in the view, pass a selector:
# delegate(eventType, selector, handler)
@delegate('click', 'button.confirm', @confirm)
```

<a id="model-binding"></a>
## Model binding
Disposal-aware event binding. Binds to the view's `@model` or `@collection`.

<a id="modelBind"></a>
### modelBind(type, handler)
* **String type - Backbone event type (e.g. 'change:title', 'error', etc )**
* **function handler**

  Listen for model events and call an appropriate handler. Ensures
  events are only bound once per handler by calling [`modelUnbind`](#modelUnbind)
  before binding.

  A common pattern is to listen for the 'change' event and trigger
  a render, or show error message for failed model validation

```coffeescript
class LikeView extends View
  initialize: ->
    @modelBind 'change' @render
    @modelBind 'error' @showErrorMessage
    super

  showErrorMessage: (message) ->
    @$('.errors').append(message)
```

<a id="modelUnbind"></a>
### modelUnbind(type, handler)
* **String type - Backbone event type (e.g. 'change:title', 'error', etc )**
* **function handler**

  Unbind a handler from a model event

<a id="modelUnbindAll"></a>
### modelUnbindAll()

  Unbind all recorded model event handlers.

<a id="pass"></a>
### pass(attribute, selector)
* **String attribute - corresponds to a field on the model**
* **String selector - a jQuery selector, object, or element**

  Simple one-way model-view binding (closing the gap on one of the
  key differences between Backbone and other frameworks like Ember,
  Angular, etc)

  Pass changed attribute values to specific elements in the view
  For form controls, the value is changed, otherwise the element
  text content is set to the model attribute value.

  Useful for form views and other forms of user input, or updating
  individual parts of the View from changed attributes

```coffeescript
@pass 'email', 'input[name="email"]'
@pass 'author', 'h2.author-name'
```


## Subviews

### subview(name, [view])
* **String name**,
* **View view (when setting the subview)**
  
  Add a subview to the View to be referenced by `name`. Calling with just the
  `name` argument will return the subview associated with that `name`.
  
  Subviews are not automatically rendered. This is often done in an
  inheriting view (i.e. in [CollectionView](./chaplin.collection_view.md)
  or your own PageView base class).

### removeSubview(nameOrView)
Remove the specified subview. Can be called with either the `name` associated with the subview, or a reference to the subview instance.

# Publish/Subscribe

The View includes the [EventBroker](./chaplin.event_broker.md) mixin
Publish/Subscribe using the [mediator](./chaplin.mediator.md)

subscribeEvent (type:String, handler:Function):mediator
unsubscribeEvent (type:String, handler:Function):mediator
unsubscribeAllEvents ():mediator
