# Chaplin.utils

Chaplin's utils provide common functions for use throughout the project.


## beget
* **returns beget function**

A standard Javascript helper function that creates an object which
delegates to another object. (see Douglas Crockford's *Javascript:
The Good Parts* for more details). Uses [Object.create](https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/Object/create)
when available, and falls back to a polyfill if not present.

## readonly(object, [*properties])
* **returns true if successful, false if unsupported**

Makes properties of **object** read-only so they cannot be overwritten
if the current environment supports it.

## wrapMethod(instance, name) ->
* **Object instance**
* **String name, property of instance**
* **returns the wrapped method**

Wrap a method in order to call the corresponding
`after-` method automatically (e.g. `afterRender` or
`afterInitialize`)

Enables a much more complex classical heirarchy when instruction
order is important

```coffeescript
bob =
  show: -> 'one'
  afterShow: -> 'two'

bob.show() # 'one'
utils.wrapMethod bob, 'show'
bob.show() # 'one' 'two'
```

## Upcase(str)
* **String str**
* **returns upcased String**

Ensure the first character of **str** is capitalized

```coffeescript
utils.upcase 'larry bird' # 'Larry bird'
utils.upcase 'AIR'        # 'AIR'
```

## underscorize: (string) ->
* **String string**
* **returns underscorized String**

Convert a camelCased string to an entirely lowercased, underscore-
separated string. Each capital leter is considered the beginning
of a word.

```coffeescript
utils.underscorize 'underScoreHelper' # under_score_helper
```

## modifierKeyPressed
* **jQuery event**
* **returns boolean**

Looks at an event object to determine if the **shift**, **alt**,
**ctrl**, or **meta** keys were pressed. Useful in link click
handling (i.e. if you need ctrl-click or shift-click to open the
link in a new window)