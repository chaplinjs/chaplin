
define(['lib/create_mediator', 'mediator'], function(createMediator, originalMediator) {
  'use strict';
  var mockMediator;
  mockMediator = createMediator();
  define('mediator', function() {
    return mockMediator;
  });
  return require(['lib/router'], function(Router) {
    var router;
    console.debug('Router loaded');
    router = new Router;
    describe('Router and Route', function() {
      console.debug('describe Router and Route');
      return it('should fire a matchRoute event', function() {
        var matchRoute;
        matchRoute = jasmine.createSpy();
        fakeMediator.subscribe('matchRoute', matchRoute);
        router.match('', 'x#y');
        router.route('/');
        expect(matchRoute).toHaveBeenCalled();
        return fakeMediator.unsubscribe('matchRoute', matchRoute);
      });
    });
    jasmineEnv.execute();
    return define('mediator', function() {
      return originalMediator;
    });
  });
});
