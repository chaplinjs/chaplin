
define(function() {
  'use strict';
  var support;
  support = {
    propertyDescriptors: (function() {
      if (!(Object.defineProperty && Object.defineProperties)) return false;
      try {
        Object.defineProperty({}, 'foo', {
          value: 'bar'
        });
        return true;
      } catch (error) {
        return false;
      }
    })()
  };
  return support;
});
