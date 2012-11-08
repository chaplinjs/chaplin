# Chaplin.View

Chaplin’s `View` class is a highly extended and adapted Backbone `View`. All views should inherit from this class to avoid repetition.

Views may subscribe to Publish/Subscribe and model/collection events in a manner which allows proper disposal. They have a standard `render` method which renders a template into the view’s root element (`@el`).

The templating function is provided by `getTemplateFunction`. The input data for the template is provided by `getTemplateData`. By default, this method just returns an object which delegates to the model attributes. Views might override the method to process the raw model data for the view.

In addition to Backbone’s `events` hash and the `delegateEvents` method, Chaplin has the `delegate` method to register user input handlers. The declarative `events` hash doesn’t work well for class hierarchies when several `initialize` methods register their own handlers. The programatic approach of `delegate` solves these problems.

Also, `@model.bind()` should not be used directly. Chaplin has `@modelBind()` which forces the handler context so the handler can be removed automatically on view disposal. When using Backbone’s naked `bind`, you have to deregister the handler manually to clear the reference from the model to the view.

### Features und purpose

- Rendering model data using templates in a conventional way
- Robust and memory-safe model binding
- Automatic rendering and appending to the DOM
- Creating subviews
- Disposal which cleans up all subviews, model bindings and Pub/Sub events

# Rendering: getTemplateFunction, render, …

Backbone.View
DRY
Your application has to provide a standard

render
getTemplateFunction
  Empty method which needs to return the compiled template function
getTemplateData
  used internally to prepare the model data for the template



# Options for auto-rendering and DOM appending

options may be specific on the model class or passed to the constructor

autoRender
  Boolean, default: false
container
  jQuery object or element, default: null
containerMethod
  String, jQuery object method, default: 'append'

# Model binding

modelBind
modelUnbind
modelUnbindAll

# Subviews

subview (name, [view])
removeSubview (nameOrView)

# Publish/Subscribe

The View includes the EventBroker mixin
Publish/Subscribe using the mediator

subscribeEvent (type:String, handler:Function):mediator
unsubscribeEvent (type:String, handler:Function):mediator
unsubscribeAllEvents ():mediator

### method1(arg1, [optional_arg], [*args])

Lorem
