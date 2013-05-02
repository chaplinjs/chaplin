# [Chaplin.Route](../src/chaplin/lib/route.coffee)

The `Chaplin Route` is used by `Chaplin.Router` to generate regular expressions and extract pramaters from a given pattern.

## Methods of `Chaplin.Route`

### createRegExp
Creates the actual regular expression that Backbone.History#LoadUrl uses to determine if the current url is a match.

### addParamName([match], [paramName])
Determines if the pattern passed is a reserved named, if not than it is added to the `@paramsName` object and returns `([^\/\?]+)` to do a replacement for the character class.

* **match**: the parameter with the colon `:user`
* **paramName**: the parameter with the colon stripped `user`

### test([path])
Tests if the route matches a path and applies any parameter constraints.  This is called by Backbone.History#Loadurl.

* **path**: a relative path to check against

### matches(criteria)
Tests if the route is equal to criteria (route name or other field).

* **criteria**:
    1. String. Will compare this.name with it.
    2. Object. Will compare this[field] with each object[field].

Returns `Boolean`.

### reverse(params)
Generates route URL from params.

* **params**:
    1. Array. List of params from which URL will be generated.
    2. Object. Named params from which URL will be generated.

Returns route url if all params were cool and `false` otherwise.

### handler([path], [options])
The handler is called by Backbone.History when the route is matched.  It is also called by [Router#route](./chaplin.router.md#routepath) and passes `changeURL: true` as an option.

* **path**: the matched path
* **options**: an optional object

### buildParams([path], [options])
Creates a proper Rails-like params hash, not an array like Backbone `matches` and `additionalParams` arguments are optional.

* **path**: the matched URL path
* **options**: an optional object

### extractParams([path])
Extracts the named parameters from the URL path.

* **path**: the URL path

### extractQueryParams([path])
Extracts the parameters from the query string.

* **path**: the URL path


## Usage

A new instance of `Chaplin.Route` is created for each route in the routes file of your application.  This occurs when the [match method](./chaplin.router.md#match-pattern-target-options-) of `Chaplin.Router` is called. The actual routes file should be in the root of your project along with your main application bootstrapper file.

The routes file is basically a module that returns an anonymous function in which the [match method](./chaplin.router.md#match-pattern-target-options-) is passed in as an argument.
