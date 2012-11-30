# Chaplin.support

Currently `Chaplin.support` only offers feature detection for `defineProperty`.

## Methods of `Chaplin.support`


<a name="propertyDescriptors"></a>

### propertyDescriptors

Determines if `Object.defineProperty` is supported. It's important to note that IE8 has an implementation of `Object.defineProperty` however the method can only be used on DOM objects.

## Usage

`Support` is used for feature detection and each method returns a boolean
indicating feature support.

## [Code](https://github.com/chaplinjs/chaplin/blob/master/src/chaplin/lib/support.coffee)
