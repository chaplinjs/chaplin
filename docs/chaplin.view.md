# [Chaplin.View](../src/chaplin/views/view.coffee)

Chaplin’s `View` class is a highly extended and adapted Backbone `View`. All views should inherit from this class to avoid repetition.

Views may subscribe to Publish/Subscribe and model/collection events in a manner which allows proper disposal. They have a standard `render` method which renders a template into the view’s root element (`@el`).

The templating function is provided by `getTemplateFunction`. The input data for the template is provided by `getTemplateData`. By default, this method just returns an object which delegates to the model attributes. Views might override the method to process the raw model data for the view.

In addition to Backbone’s `events` hash and the `delegateEvents` method, Chaplin has the `delegate` method to register user input handlers. The declarative `events` hash doesn’t work well for class hierarchies when several `initialize` methods register their own handlers. The programatic approach of `delegate` solves these problems.

Also, `@model.on()` should not be used directly. Backbone has `@listenTo(@model, ...)` which forces the handler context so the handler can be removed automatically on view disposal. When using Backbone’s naked `on`, you have to deregister the handler manually to clear the reference from the model to the view.

## Features and purpose

* Rendering model data using templates in a conventional way
* Robust and memory-safe model binding
* Automatic rendering and appending to the DOM
* Registering regions
* Creating subviews
* Disposal which cleans up all subviews, model bindings and Pub/Sub events

### initialize(options)
* **options (default: empty hash)**
    * `autoRender` see [autoRender](#autorender)
    * `autoAttach` see [autoAttach](#autoattach)
    * `container` see [container](#container)
    * `containerMethod` see [containerMethod](#containermethod)
    * all standard [Backbone constructor
  options](http://backbonejs.org/#View-constructor) (`model`, `collection`,
  `el`, `id`, `className`, `tagName` and `attributes`)

  `options` may be specific on the view class or passed to the constructor. Passing
  in options during instantiation overrides the View prototype's defaults.

  Views must always call `super` from their `initialize` methods. Unlike
  Backbone's initialize method, Chaplin's initialize is required to
  create the instance's subviews and listen for model or collection disposal.

## Rendering: getTemplateFunction, render, …

  Your application should provide a standard way of rendering DOM
  nodes by creating HTML from templates and template data. Chaplin
  provides `getTemplateFunction` and `getTemplateData` for this purpose.

  Set [`autoRender`](#autorender) to true to enable rendering upon
  View instantiation. If [`autoAttach`](#autoattach) is enabled, this
  will automatically append to the view to a [`container`](#container)
  The method of appending can be overridden using the
  [`containerMethod`](#containermethod) property
  (to `html`, `before`, `prepend`, etc).

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


### getTemplateData()
* **function that returns Object (throws error if not overriden)**

  Empty method which returns the prepared model data for the template. Should
  be overriden by inheriting classes (often from model data).

```coffeescript
getTemplateData: ->
  @model.attributes

...

getTemplateData: ->
  title: 'Winnetou', author: 'Karl May'

```

```javascript
getTemplateData: function() {
  return this.model.attributes;
}

...

getTemplateData: function() {
  return {title: 'Winnetou', author: 'Karl May'};
}
```

  often overriden in a base model class to intelligently pick out attributes

### render
  By default calls the `templateFunction` with the `templateData` and sets the html
  of the `$el`. Can be overriden in your base view if needed, though should be
  suitable for the majority of cases.

## attach
  Attach is called after the prototype chain has completed for View#render.
  It attaches the View to its `container` element and fires an `addedToDOM` event
  at the view on success.

## Options for auto-rendering and DOM appending

### autoRender
* **Boolean, default: false**

  Specifies whether the View's `render` method should be called automatically when
  a view is instantiated.

### autoAttach
* **Boolean, default: true**

  Specifies whether the View's `attach` method should be called automatically after
  `render` was called.

### container
* **jQuery object, selector string, or element, default: null**

  A container element into which the view’s element will be rendered.
  This may be an DOM element, a jQuery object or a selector string.
  In the latter case the container must already exist in the DOM.

  Set this property in a derived class to specify the container element.
  As an alternative you might pass a `container` option to the constructor.

  When the `container` is set and [`autoAttach`](#autoattach) is true, the view
  is automatically inserted into the container when it’s rendered
  (using the [`attach`](#attach) method).

  A container is often an empty element within a parent view.

### containerMethod
* **String, jQuery object method (default: 'append')**

  Method which is used for adding the view to the DOM via the `container`
  element. (Like jQuery’s `html`, `prepend`, `append`, `after`, `before` etc.)

## Event delegation

### listen
* **Object**

  Property that contains declarative event bindings to non-DOM
  listeners. Just like [Backbone.View#events](http://backbonejs.org/#View),
  but for models / collections / mediator etc.

```coffeescript
class SomeView extends View
  listen:
    # Listen to view events with @on.
    'eventName': 'methodName'
    # Same as @listenTo @model, 'change:foo', this[methodName].
    'change:foo model': 'methodName'
    # Same as @listenTo @collection, 'reset', this[methodName].
    'reset collection': 'methodName'
    # Same as @subscribeEvent 'pubSubEvent', this[methodName].
    'pubSubEvent mediator': 'methodName'
    # The value can also be a function.
    'eventName': -> alert 'Hello!'
```

```javascript
var SomeView = View.extend({
  listen: {
    // Listen to view events with @on.
    'eventName': 'methodName',
    // Same as @listenTo @model, 'change:foo', this[methodName].
    'change:foo model': 'methodName',
    // Same as @listenTo @collection, 'reset', this[methodName].
    'reset collection': 'methodName',
    // Same as @subscribeEvent 'pubSubEvent', this[methodName].
    'pubSubEvent mediator': 'methodName',
    // The value can also be a function.
    'eventName': function() {alert('Hello!')}
  }
});
```

### delegate(eventType, [selector], handler)
* **String eventType - jQuery DOM event, (e.g. 'click', 'focus', etc )**,
* **String selector (optional, if not set will bind to the view's $el)**,
* **function handler (automatically bound to `this`)**

Backbone's `events` hash doesn't work well with inheritance, so
Chaplin provides the `delegate` method for this purpose. `delegate`
is a wrapper for jQuery's `@$el.on` method, and has the same
method signature.

For events, affecting the whole view the signature is `delegate(eventType, handler)`:

```coffeescript
@delegate('click', @clicked)
```

```javascript
this.delegate('click', this.clicked);
```

For events only affecting an element or colletion of elements in the view, pass a selector too `delegate(eventType, selector, handler)`:

```coffeescript
@delegate('click', 'button.confirm', @confirm)
```

```javascript
this.delegate('click', 'button.confirm', this.confirm);
```

## Regions

Provides a means to give canonical names to selectors in the view. Instead of
binding a view to `#page .container > .sidebar` (via the container) you would
bind it to the declared region `sidebar` which is registered by the view that
contained `#page .container > .sidebar`. This decouples views from those that
nests them. It allows for layouts to be drastically changed without changing
the template.

### region

This is the region that the view will be bound to. This property is not
meant to be set on the prototype -- it is meant to be passed in as part
of the options hash.

Both of the following code snippets will bind the view `MyView` to the
declared region `sidebar`.

This one sets the region directly on the prototype:

```coffeescript
# myview.coffee
class MyView extends Chaplin.View
  region: 'sidebar'

# my_controller.coffee
# [...] inside action method
@view = new MyView()
```

And this one passes in the value of region to the view constructor:

```coffeescript
# myview.coffee
class MyView extends Chaplin.View

# my_controller.coffee
# [...] inside action method
@view = new MyView {region: 'sidebar'}
```

However the latter case allows the controller (through whatever logic) decide
where to place the view.

### regions

Region registration hash that works much like the declarative events hash
present in Backbone.

The following snippet will register the named regions `sidebar` and `body` and
bind them to their respective selectors.

```coffeescript
# myview.coffee
class MyView extends Chaplin.View
  regions:
    '#page .container > .sidebar': 'sidebar'
    '#page .container > .content': 'body'
```

When the view is initialzied the regions hashes of all base classes are
gathered and registered as well. When two views in an inheritance tree
both register a region of the same name, the selector of the most-derived view
is used.

### registerRegion(selector, name)
* **String selector**,
* **String name**

Functionally registers a region exactly the same as if it were in the regions
hash. Meant to be called in the `initialize` method as the following code
snippet (which is identical to the previous one using the `regions` hash).

```coffeescript
class MyView extends Chaplin.View
  initialize: ->
    super
    @registerRegion '#page .container > .sidebar', 'sidebar'
    @registerRegion '#page .container > .content', 'body'
```

### unregisterRegion(name)
* **String name**

Removes the named region as if it was not registered. Does nothing if
there is no region named `name`.

### unregisterAllRegions()

Removes all regions registered by this view, automatically called on
`View#dispose`.


## Subviews

Subviews are usually used for limited scenarios when you want to split a view up into
logical sections that are continuously re-rendered or form wizards, etc.
but *only when dealing with the same model*.

### subview(name, [view])
* **String name**,
* **View view (when setting the subview)**

  Register a subview with the given `name`. Calling the method with just the
  `name` argument will return the subview associated with that `name`.

  This just registers a subview so it can be disposed when its parent view is disposed.
  Subviews are not automatically rendered and attached to the current view.
  You can use the `autoRender` and `container` options to render and attach the view.

  If you register a subview with the same name twice, the previous subview will be disposed.
  This ensures that there is only one subview under the given name.

### removeSubview(nameOrView)

Remove the specified subview and dispose it. Can be called with either the `name` associated with the subview, or a reference to the subview instance.

### Usage

```coffeescript
class YourView extends View

  render: ->
    super
    infoboxView = new InfoBox autoRender: true, container: @el
    @subview 'infobox', infoboxView
```

# Publish/Subscribe

The View includes the [EventBroker](./chaplin.event_broker.md) mixin to provide Publish/Subscribe capabilities using the [mediator](./chaplin.mediator.md)

## [Methods](./chaplin.event_broker.md#methods-of-chaplineventbroker) of `Chaplin.EventBroker`

### publishEvent(event, arguments...)
Publish the global `event` with `arguments`.

### subscribeEvent(event, handler)
Unsubcribe the `handler` to the `event` (if it exists) before subscribing it. It is like `Chaplin.mediator.subscribe` except it cannot subscribe twice.

### unsubscribeEvent(event, handler)
Unsubcribe the `handler` to the `event`. It is like `Chaplin.mediator.unsubscribe`.

### unsubscribeAllEvents()
Unsubcribe all handlers for all events.
