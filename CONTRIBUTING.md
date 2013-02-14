# Contributing to Chaplin
For non-technical issues (questions etc.),
use [ost.io](http://ost.io/chaplinjs/chaplin) forum or our mailing list.

If you submit changes to coffeescript code, make sure it conforms with the style guide.

## Chaplin code style guide

Unless stated otherwise, follow the [CoffeeScript style guide](https://github.com/polarmobile/coffeescript-style-guide).

## Commenting and Whitespace

* Use whitespace generously.
* Use comments generously and wisely. Keep them short and helpful, use the simplest language possible.

## Code readability

* Write simple and verbose code instead of complex and dense. Don’t minify the code manually, don’t use ugly tricks to reduce the resulting code size.
* Explicit is better than implicit. When in doubt, use several statements and use additional variables instead of putting everything in a huge expression statement.
* Check if the CoffeeScript code makes sense when compiled to JavaScript. The JavaScript code should be readable, brief and clear. Avoid CoffeeScript features that create overly complex and obscure Javascript code.

## CoffeeScript woes

What can be done with pure CoffeeScript should be done by CoffeeScript, not Underscore or jQuery.

Exception: Don’t use CoffeeScript if the compiled JavaScript code is extremely verbose or inefficient. For list comprehension and map operations, CoffeeScript creates an immediately-invoked function which leads to horrible verbose and inefficient code. Also, the CoffeeScript isn’t always readable.

Avoid:

```
foo = (x for x in y)
foo = for …
  …
foo = while …
  …
```

Better:

```
foo = []
for …
  foo.push …
  // or
  foo[index] = …
```

This is more efficient and compiles to less JavaScript code. CoffeeScript’s syntactic sugar has little value here.

Use simple CoffeeScript `for in` / `for of` loops when applicable. Use the semantic `_.map`, `_.filter` functions from Underscore if necessary. When using Underscore, use the canonical ECMAScript 5 names (for example, `_.reduce` instead of  `_.inject`).

Take care of the return value of functions. CoffeeScript adds implicit return statements. If a loop is at the end of a function, CoffeeScript creates a list comprehension which might be unnecessary:

```
method: ->
  for …
    …
```

Add an return statement to avoid this.

```
method: ->
  for …
    …
  return
```

## Type checking

Avoid using Underscore’s type checking functions. They aren’t needed in most of the cases. Use the simplest way which is appropriate:

Use duck typing instead of requiring a specific type where applicable.

When expecting objects (non-primitives), just check for truthyness. This is fast and easy to read. If the value is a truthy primitive, the code will fail when trying to use undefined properties.

Use the CoffeeScript `?` operator to exclude `null` and `undefined` while allowing all other types (truthy or falsy). But use the operator sparingly, avoid chains like `foo?.bar?.quux` because they compile to unreadable and inefficient JavaScript code. For example, use `if foo and foo.bar` instead of `if foo?.bar` if truthyness is okay.

- Check for `string.length`, `number > 0` etc.
- Use `typeof` to detect `function`, `string`, `number` (if type detection is necessary)
- Use `is/isnt null` to detect `null`
- Use `obj.prop is/isnt undefined` to detect `undefined`
- Use the `of` operator to check for properties that might be inherited
- Use `_.has` for `hasOwnProperty` checks

## Chaining function calls

Use this style of chaining function calls:

```
$('#selector').addClass 'class'
foo(4).bar 8
```

Avoid the “function grouping style”, as described in the [CoffeeScript style guide](https://github.com/polarmobile/coffeescript-style-guide).

## Spec style

Use `expect(…).to.be(…)` instead of `.to.equal()`.

Use the bridge between Expect.js and Sinon.js for nice spy/stub/mock expectations, see [sinon-expect.js](https://github.com/lightsofapollo/sinon-expect/blob/master/lib/sinon-expect.js).

## Git style

Follow [the git style guide](https://github.com/paulmillr/code-style-guides/blob/master/README.md#git).
