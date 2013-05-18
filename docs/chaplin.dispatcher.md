---
layout: default
title: Chaplin.Dispatcher
module_path: src/chaplin/dispatcher.coffee
---

The `Dispatcher` sits between the router and the controllers. It listens for a routing event to occur and then:

* Disposes the previously active controller
* Loads the target controller module
* Instantiates the new controller
* Calls the target action

<h2 id="methods">Methods</h2>

<h3 class="module-member" id="initialize">initialize([options={}])</h3>

* **options**:
    * **controllerPath**: the path to the folder for the controllers. *Default: '/controllers'*
    * **controllerSuffix**: the suffix used for controller files. *Default: '_controller'*
