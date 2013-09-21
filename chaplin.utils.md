---
layout: default
title: Chaplin.utils
module_path: src/chaplin/lib/utils.coffee
Chaplin: utils
---

Chaplin’s utils provide common functions for use throughout the project.

These functions are generic and not related to any specific Chaplin components. Useful functions for messing with Chaplin are available in [Chaplin.helpers](chaplin.helpers.html).

<h3 class="module-member" id="beget">beget(parent)</h3>
* **returns a new object with `parent` as its prototype**

A standard Javascript helper function that creates an object which delegates to another object. (see Douglas Crockford's *Javascript: The Good Parts* for more details). Uses [Object.create](https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/Object/create) when available, and falls back to a polyfill if not present.

<h3 class="module-member" id="readonly">readonly(object, [*properties])</h3>
* **returns true if successful, false if unsupported by the browser’s runtime**

Makes properties of **object** read-only so they cannot be overwritten. The success of this operation depends on the current environment’s support.

<h3 class="module-member" id="getPrototypeChain">getPrototypeChain(object)</h3>
* **Object object**

Gets the whole chain of prototypes for `object`.

<h3 class="module-member" id="getAllPropertyVersions">getAllPropertyVersions(object, property)</h3>
* **Object object**
* **String property**

Get all different value versions for `property` from `object`’s prototype chain. Usage:

```coffeescript
class A
  prop: 1
class B extends A
  prop: 2

b = new B
getAllPropertyVersions b, 'prop'  # => [1, 2]
```

```javascript
function A() {}
A.prototype.prop = 1;

function B() {}
B.prototype = Object.create(A);

var b = new B;
getAllPropertyVersions(b, 'prop'); // => [1, 2]
```

<h3 class="module-member" id="upcase">upcase(str)</h3>
* **String `str`**
* **returns upcased version of `str`**

Ensure the first character of `str` is capitalized

```coffeescript
utils.upcase 'larry bird' # 'Larry bird'
utils.upcase 'AIR'        # 'AIR'
```

```javascript
utils.upcase('larry bird'); // 'Larry bird'
utils.upcase('AIR');        // 'AIR'
```

<h3 class="module-member" id="modifierKeyPressed">modifierKeyPressed(event)</h3>
* **jQuery normalized event object `event`**
* **returns boolean**

Looks at an event object `event` to determine if the **shift**, **alt**, **ctrl**, or **meta** keys were pressed. Useful in link click handling (i.e. if you need ctrl-click or shift-click to open the link in a new window).

<h3 class="module-member" id="queryParams.stringify">queryParams.stringify(object)</h3>
* **Object object**

Returns a query string from a hash.

<h3 class="module-member" id="queryParams.parse">queryParams.parse(string)</h3>
* **String string**

Returns a hash with query parameters from a query string.
