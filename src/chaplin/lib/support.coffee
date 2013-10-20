'use strict'

# Feature detection
# -----------------

support =
  # Test for defineProperty support
  # (IE 8 knows the method but will throw an exception).
  propertyDescriptors: do ->
    unless typeof Object.defineProperty is 'function' and
    typeof Object.defineProperties is 'function'
      return false
    try
      o = {}
      Object.defineProperty o, 'foo', value: 'bar'
      return o.foo is 'bar'
    catch error
      return false

# Return our creation.
module.exports = support
