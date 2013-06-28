---
layout: default
title: Chaplin.Dispatcher
module_path: src/chaplin/dispatcher.coffee
Chaplin: Dispatcher
---

The `Dispatcher` sits between the router and the various controllers of your application. It listens for a routing event to occur and then:

* disposes the previously active controller,
* loads the target controller module,
* instantiates the new controller, and
* calls the target action.

<h2 id="methods">Methods</h2>

<h3 class="module-member" id="initialize">initialize([options={}])</h3>

* **options**:
    * **controllerPath** (default `'/controllers'`): the path to the folder for the controllers.
    * **controllerSuffix** (default `'_controller':`) the suffix used for controller files.
Both of these options serve to generate path names for autoloading controller modules.
