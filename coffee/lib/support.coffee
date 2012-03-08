define ->
  'use strict'

  # Feature detection
  # -----------------

  support =

    # Test for defineProperty support
    # (IE 8 knows the method but will throw an exception)
    propertyDescriptors: do ->
      return false unless Object.defineProperty and Object.defineProperties
      try
        Object.defineProperty {}, 'foo', value: 'bar'
        return true
      catch error
        return false

  support