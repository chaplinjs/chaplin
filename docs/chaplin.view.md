---
layout: default
title: Chaplin.View
module_path: src/chaplin/views/view.coffee
Chaplin: View
---

Chaplin’s `View` class is a highly extended and adapted subclass of `Backbone.View`. By default, all views should inherit from this class to take advantage of its additions and improved memory management.

Views may subscribe to global pub/sub and model/collection events in a manner which allows proper disposal. They have a standard `render` method which renders a template into the view’s root element (`this.el`).

The templating function is provided by `this.getTemplateFunction`. The input data for the template is provided by `this.getTemplateData`. By default, this method just returns an object delegating to the model attributes. Views might override the method to process the raw model data for the view.

In addition to Backbone’s `events` hash and the `delegateEvents` method, Chaplin has the `delegate` method to register user input handlers. The declarative `events` hash doesn’t work well for class hierarchies when several `initialize` methods register their own handlers. The programatic approach of `delegate` solves these problems.

When establishing bindings between view and model, `this.model.on()` should not be used directly. Instead,  Backbone’s built-in methods for handling bindings, such as `this.listenTo(this.model, ...)` should be used, so handlers can be removed automatically on view disposal to prevent memory leakage.

## Features and purpose

* Rendering model data using templates in a conventional way
* Robust and memory-safe model binding
* Automatic rendering and appending to the DOM
* Registering regions
* Creating subviews
* Disposal which cleans up all subviews, model bindings and pub/sub events

<h2 id="methods">Methods</h2>

<h3 class="module-member" id="initialize">initialize(options)</h3>
* **options (default: empty hash)**
    * `autoRender` see [autoRender](#autoRender)
    * `autoAttach` see [autoAttach](#autoAttach)
    * `container` see [container](#container)
    * `containerMethod` see [containerMethod](#containerMethod)
    * all standard [Backbone constructor options](http://backbonejs.org/#View-constructor) (`model`, `collection`, `el`, `id`, `className`, `tagName` and `attributes`)

  `options` may be specific on the view class or passed to the constructor. Passing in options during instantiation overrides the View prototype's defaults.

  Views must always call `super` from their `initialize` methods. Unlike Backbone’s `initialize` method, Chaplin’s `initialize` is required to create the instance’s subviews and listen for model or collection disposal.

## Rendering: `getTemplateFunction`, `render`, …

  Your application should provide a standard way of rendering DOM nodes by creating HTML from templates and template data. Chaplin provides `getTemplateFunction` and `getTemplateData` for this purpose.

  Set [`autoRender`](#autoRender) to true to enable rendering upon View instantiation. If [`autoAttach`](#autoAttach) is enabled, this will automatically append the view to a [`container`](#container). The method of appending can be overridden using the [`containerMethod`](#containerMethod) property (to `html`, `before`, `prepend`, etc).

<h3 class="module-member" id="getTemplateFunction">getTemplateFunction()</h3>
* **function (throws error if not overriden)**

  Core method that returns the compiled template function. Usually set application-wide in a base view class.

  A common implementation will take a passed in `template` string and return a compiled template function (e.g. a Handlebars or Underscore template function).

```coffeescript
@template = require 'templates/comment_view'
```
```javascript
this.template = require('templates/comment_view');
```

or if using templates in the DOM

```coffeescript
@template = $('#comment_view_template').html()
```
```javascript
this.template = $('#comment_view_template').html();
```

if using Handlebars

```coffeescript
getTemplateFunction: ->
  Handlebars.compile @template
```
```javascript
getTemplateFunction: function() {
  return Handlebars.compile(this.template);
}
```

or if using underscore templates

```coffeescript
getTemplateFunction: ->
  _.template @template
```
```javascript
getTemplateFunction: function() {
  return _.template(this.template);
}
```

Packages like [Brunch With Chaplin](https://github.com/paulmillr/brunch-with-chaplin) precompile the template functions to improve application performance.

<h3 class="module-member" id="getTemplateData">getTemplateData()</h3>
* **function that returns Object**

  Empty method which returns the prepared model data for the template. Should be overriden by inheriting classes (often from model data).

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

Often overriden in a base model class to intelligently pick out attributes.

<h3 class="module-member" id="render">render</h3>
By default calls the `templateFunction` with the `templateData` and sets the HTML of the `$el`. Can be overriden in your base view if needed, though this should be suitable for the majority of cases.

<h3 class="module-member" id="attach">attach</h3>
The `attach` method is called after the prototype chain has completed for `View#render`. It attaches the view to its `container` element and fires an `'addedToDOM'` event on the view on success.

## General options

<h3 class="module-member" id="optionNames">optionNames</h3>
* **array (default list of options)**

List of options that will be picked from constructor.

Easy to extend:

```coffeescript
optionNames: View::optionNames.concat ['template']
```

```javascript
optionNames: View.prototype.optionNames.concat(['template'])
```

## Options for rendering

<h3 class="module-member" id="noWrap">noWrap</h3>
* **boolean (default `false`)**

Specifies whether the default Backbone behavior of wrapping the template with an element, as specified with `tagName`, should be used. When `true` the template will not be wrapped and the template will be rendered as-is and must contain 1 top-level element. Works when using a `region`, `container`, or as a `CollectionView` item.

## Options for auto-rendering and DOM appending

<h3 class="module-member" id="autoRender">autoRender</h3>
* **boolean (default `false`)**

Specifies whether the view’s `render` method should be called automatically when a view is instantiated.

<h3 class="module-member" id="autoAttach">autoAttach</h3>
* **boolean (default `true`**

Specifies whether the view’s `attach` method should be called automatically after `render` was called.

<h3 class="module-member" id="container">container</h3>
* **jQuery object, selector string, or element (default `null`)**

A container element into which the view’s element will be rendered. This may be a DOM element, a jQuery object or a selector string. In the latter case the container must already exist in the DOM.

Set this property in a derived class to specify the container element. As an alternative you might pass a `container` option to the constructor.

When the `container` is set and [`autoAttach`](#autoAttach) is true, the view is automatically inserted into the container when it’s rendered (using the [`attach`](#attach) method).

A container is often an empty element within a parent view.

<h3 class="module-member" id="containerMethod">containerMethod</h3>
* **String, jQuery object method (default `'append'`)**

Method which is used for adding the view to the DOM via the `container` element. (Like jQuery’s `html`, `prepend`, `append`, `after`, `before` etc.)

## Event delegation

<h3 class="module-member" id="listen">listen</h3>
* **Object**

Chaplin's declarative event bindings follow [Backbone's built-in event catalog](http://backbonejs.org/#Events-catalog), with the added benefit of [automatically removable event listeners](http://docs.chaplinjs.org/events.html#toc_1). You can listen to models/collections/mediator etc.

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
    // Same as this.listenTo(this.model, 'change:foo', this[methodName])
    'change:foo model': 'methodName',
    // Same as this.listenTo(this.collection, 'reset', this[methodName])
    'reset collection': 'methodName',
    // Same as this.subscribeEvent('pubSubEvent', this[methodName])
    'pubSubEvent mediator': 'methodName',
    // The value can also be a function.
    'eventName': function() {alert('Hello!')}
  }
});
```


<h3 class="module-member" id="delegate">delegate(eventType, [selector], handler)</h3>
* **String eventType - jQuery DOM event (e.g. `'click'`, `'focus'`, etc.)**,
* **String selector (optional, if not set will bind to the view’s `$el`)**,
* **function handler (automatically bound to `this`)**
* **returns the bound handler function**

Backbone’s `events` hash doesn't work well with inheritance, so Chaplin provides the `delegate` method for this purpose. `delegate` is a wrapper for jQuery’s `this.$el.on` method, and has the same method signature.

For events affecting the whole view the signature is `delegate(eventType, handler)`:

```coffeescript
@delegate('click', @clicked)
```

```javascript
this.delegate('click', this.clicked);
```

For events only affecting an element or colletion of elements in the view, pass a selector, too, `delegate(eventType, selector, handler)`:

```coffeescript
@delegate('click', 'button.confirm', @confirm)
```

```javascript
this.delegate('click', 'button.confirm', this.confirm);
```

### undelegate(eventType, [selector], handler)
* **String eventType - jQuery DOM event (e.g. `'click'`, `'focus'`, etc.)**,
* **String selector (optional, if not set will bind to the view’s `$el`)**,
* **function handler (automatically bound to `this`)**
* **returns the bound handler function**

Allows to remove DOM event handlers that have been added using `delegate`. `undelegate` is a wrapper for jQuery’s `this.$el.off` method, and has the same method signature.

Since `delegate` automatically binds the handler function to the view, you need to pass the bound handler to remove it. This is a new function and not the same as the original handler passed to `delegate`.

To allow this, `delegate` returns the bound handler so you can save it for later removal:

```coffeescript
# CoffeeScript
@boundConfirm = @delegate 'click', 'button.confirm', @confirm
# Later:
@undelegate 'click', 'button.confirm', @boundConfirm
```

```coffeescript
// JavaScript
this.boundConfirm = this.delegate('click', 'button.confirm', this.confirm);
// Later:
this.undelegate('click', 'button.confirm', this.boundConfirm);
```

## Regions

Regions provide a means to give canonical names to selectors in the view. Instead of binding a view to `#page .container > .sidebar` (via the container) you would bind it to the declared region `sidebar` which is registered by the view that contained `#page .container > .sidebar`. This decouples views from those that nest them. It allows for layouts to be drastically changed without changing the template.

<h3 class="module-member" id="region">region</h3>

This is the region that the view will be bound to. This property is not meant to be set on the prototype — it is meant to be passed in as part of the options hash.

Both of the following code snippets will bind the view `MyView` to the declared region `sidebar`.

This one sets the region directly on the prototype:

```coffeescript
# myview.coffee
class MyView extends Chaplin.View
  region: 'sidebar'

# my_controller.coffee
# [...] inside action method
@view = new MyView()
```
```javascript
// myview.js
var MyView = Chaplin.View.extend({
  region: 'sidebar'
});

// my_controller.js
// [...] inside action method
this.view = new MyView();
```

And this one passes in the value of region to the view constructor:

```coffeescript
# myview.coffee
class MyView extends Chaplin.View

# my_controller.coffee
# [...] inside action method
@view = new MyView {region: 'sidebar'}
```
```javascript
// myview.js
var MyView = Chaplin.View.extend({});

// my_controller.js
// [...] inside action method
this.view = new MyView({region: 'sidebar'});
```

However the latter case is more flexible, as it leaves it to the controller to decide (through whatever logic) where to place the view.

<h3 class="module-member" id="regions">regions</h3>

A region registration hash that works much like the declarative events hash present in Backbone. Region names are specifyed as keys, region selectors as values. If the region selector is empty (`''`), the view’s own DOM element will be selected.

The following snippet will register the named regions `sidebar` and `body` and bind them to their respective selectors directly on the prototype:

```coffeescript
# myview.coffee
class MyView extends Chaplin.View
  regions:
    'sidebar': '#page .container > .sidebar'
    'body': '#page .container > .content'
    'myview': ''
```
```javascript
// myview.js
var MyView = Chaplin.View({
  regions: {
    'sidebar': '#page .container > .sidebar',
    'body': '#page .container > .content',
    'myview': ''
  }
});
```

And this one passes in the values of regions to the view constructor:

```coffeescript
# myview.coffee
class MyView extends Chaplin.View

# my_controller.coffee
# [...] inside action method
@view = new MyView
  regions:
    'sidebar': '#page .container > .sidebar'
    'body': '#page .container > .content'
    'myview': ''
```
```javascript
// myview.js
var MyView = Chaplin.View({});

// my_controller.js
// [...] inside action method
this.view = new MyView({
  regions: {
    'sidebar': '#page .container > .sidebar',
    'body': '#page .container > .content',
    'myview': ''
  }
});
```

When the view is initialized, the regions hashes of all base classes are gathered and registered as well. When two views in an inheritance tree both register a region of the same name, the selector of the most-derived view is used.

<h3 class="module-member" id="registerRegion">registerRegion(selector, name)</h3>
* **String selector**,
* **String name**

Functionally registers a region exactly the same as if it were in the regions hash. It is meant to be called in the `initialize` method as in the following code snippet (which is identical to the previous one using the `regions` hash).

```coffeescript
class MyView extends Chaplin.View
  initialize: ->
    super
    @registerRegion 'sidebar', '#page .container > .sidebar'
    @registerRegion 'body', '#page .container > .content'
    @registerRegion 'myview', ''
```
```javascript
var MyView = Chaplin.View.extend({
  initialize: function() {
    Chaplin.View.prototype.initialize.apply(this, arguments);
    this.registerRegion('sidebar', '#page .container > .sidebar');
    this.registerRegion('body', '#page .container > .content');
    this.registerRegion('myview', '');
  }
});
```

<h3 class="module-member" id="unregisterRegion">unregisterRegion(name)</h3>
* **String name**

Removes the named region as if it was not registered. Does nothing if there is no region named `name`.

<h3 class="module-member" id="unregisterAllRegions">unregisterAllRegions()</h3>

Removes all regions registered by this view, automatically called on `View#dispose`.


## Subviews

Subviews are usually used for limited scenarios when you want to split a view up into logical sections that are continuously re-rendered or form wizards, etc., though this is *only* advisable, as long as they all dealing with the same model.

<h3 class="module-member" id="subview">subview(name, [view])</h3>
* **String name**,
* **View view (when setting the subview)**

Register a subview with the given `name`. Calling the method with just the `name` argument will return the subview associated with that `name`.

This just registers a subview so it can be disposed when its parent view is disposed. Subviews are not automatically rendered and attached to the current view. You can use the `autoRender` and `container` options to render and attach the view.

If you register a subview with the same name twice, the previous subview will be disposed. This ensures that there is only one subview under the given name.

<h3 class="module-member" id="removeSubview">removeSubview(nameOrView)</h3>

Remove the specified subview and dispose it. Can be called with either the `name` associated with the subview, or a reference to the subview instance.

#### Usage

```coffeescript
class YourView extends View

  render: ->
    super
    infoboxView = new InfoBox autoRender: true, container: @el
    @subview 'infobox', infoboxView
```
```javascript
var YourView = View.extend({
  render: function() {
    View.prototype.render.apply(this, arguments);
    var infoboxView = new InfoBox({autoRender: true, container: this.el});
    this.subview('infobox', infoboxView);
  }
});
```

# Publish/Subscribe

`View` includes the [EventBroker](./chaplin.event_broker.html) mixin to provide publish/subscribe capabilities using the [mediator](./chaplin.mediator.html)

## [Methods](./chaplin.event_broker.html#methods) of `Chaplin.EventBroker`

<h3 class="module-member" id="publishEvent">publishEvent(event, arguments...)</h3>
Publish the global `event` with `arguments`.

<h3 class="module-member" id="subscribeEvent">subscribeEvent(event, handler)</h3>
Unsubcribe the `handler` for the given `event` (if it exists) before subscribing it. It is like `Chaplin.mediator.subscribe` except it cannot subscribe twice.

<h3 class="module-member" id="unsubscribeEvent">unsubscribeEvent(event, handler)</h3>
Unsubcribe the `handler` to the `event`. It is like `Chaplin.mediator.unsubscribe`.

<h3 class="module-member" id="unsubscribeAllEvents">unsubscribeAllEvents()</h3>
Unsubcribe all handlers for all events.
