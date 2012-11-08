# Chaplin.Dispatcher

The `Dispatcher` sits between the router and the controllers. It listens for routing events, loads the target controller module if one happen, creates a controller instance and calls the target action. The previously active controller is automatically disposed.

## Methods of `Chaplin.Dispatcher`

<a name="initialize"></a>

### initialize( [options={}] )

* **options**:
    * **controllerPath**: the path to the folder for the controllers. *Default: '/controllers'*
    * **controllerSuffix**: the suffix used for controller files. *Default: '_controller'*

## Usage
A specific controller can be started programatically by publishing an app-wide `!startupController` event which will be handled by the `Dispatcher`:

```coffeescript
Chaplin.mediator.publish '!startupController', 'controller', 'action', params
```

## [Code](https://github.com/chaplinjs/chaplin/blob/master/src/chaplin/dispatcher.coffee)
