
define(['chaplin/lib/create_mediator'], function(createMediator) {
  'use strict';
  var mediator;
  mediator = createMediator({
    createRouterProperty: true,
    createUserProperty: true
  });
  return mediator;
});
