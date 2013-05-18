---
layout: default
title: Chaplin.support
module_path: src/chaplin/lib/support.coffee
---

Provides feature detection that is used internally to determine the code path
so that ECMAScript 5 features can be used and not break compatibility with
engines that don't understand the newer features.

<h3 class="module-member" id="propertyDescriptors">propertyDescriptors</h3>

Indicates if **[Object.defineProperty](https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/Object/defineProperty)** is supported. It's
important to note that while IE8 has an implementation of
`Object.defineProperty`, the method can only be used on DOM objects. This takes
that in to account when determining support.
