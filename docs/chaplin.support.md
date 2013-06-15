---
layout: default
title: Chaplin.support
module_path: src/chaplin/lib/support.coffee
---

Provides feature detection that is used internally to determine the code path so that ECMAScript 5 features can be used if possible, without breaking compatibility with non-compliant engines.

<h3 class="module-member" id="propertyDescriptors">propertyDescriptors</h3>

Indicates if **[Object.defineProperty](https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/Object/defineProperty)** is supported. It’s important to note that while Internet Explorer 8 has an implementation of `Object.defineProperty`, the method can only be used on DOM objects. This implementation takes this fact into account when determining support.
