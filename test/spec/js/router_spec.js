
define(['mediator', 'lib/router'], function(mediator, Router) {
  'use strict';  return describe('Router and Route', function() {
    var matchRoute, params, route, router;
    router = route = params = void 0;
    matchRoute = function(_route, _params) {
      route = _route;
      return params = _params;
    };
    beforeEach(function() {
      router = new Router();
      return mediator.subscribe('matchRoute', matchRoute);
    });
    afterEach(function() {
      route = params = undefined;
      return mediator.unsubscribe('matchRoute', matchRoute);
    });
    it('should create a Backbone.History instance', function() {
      return expect(Backbone.history instanceof Backbone.History).toBe(true);
    });
    it('should fire a matchRoute event', function() {
      matchRoute = jasmine.createSpy();
      mediator.subscribe('matchRoute', matchRoute);
      router.match('', 'x#y');
      router.route('/');
      expect(matchRoute).toHaveBeenCalled();
      return mediator.unsubscribe('matchRoute', matchRoute);
    });
    it('should match correctly', function() {
      var routed;
      matchRoute = jasmine.createSpy();
      mediator.subscribe('matchRoute', matchRoute);
      router.match('correct-match1', 'null#null');
      router.match('correct-match2', 'null#null');
      routed = router.route('/correct-match1');
      expect(routed).toBe(true);
      expect(matchRoute.calls.length).toBe(1);
      return mediator.unsubscribe('matchRoute', matchRoute);
    });
    it('should extract URL parameters', function() {
      router.match('params/:one/:p_two_123/three', 'null#null');
      router.route('/params/123-foo/456-bar/three');
      expect(typeof params).toBe('object');
      expect(params.one).toBe('123-foo');
      return expect(params.p_two_123).toBe('456-bar');
    });
    it('should provide controller name and action', function() {
      router.match('controller/action', 'controller#action');
      router.route('/controller/action');
      expect(typeof route).toBe('object');
      expect(route.controller).toBe('controller');
      return expect(route.action).toBe('action');
    });
    it('should impose constraints', function() {
      matchRoute = jasmine.createSpy();
      mediator.subscribe('matchRoute', matchRoute);
      router.match('constraints/:id', 'null#null', {
        constraints: {
          id: /^\d+$/
        }
      });
      router.route('/constraints/123-foo');
      expect(matchRoute).not.toHaveBeenCalled();
      router.route('/constraints/123');
      expect(matchRoute).toHaveBeenCalled();
      return mediator.unsubscribe('matchRoute', matchRoute);
    });
    it('should pass fixed parameters', function() {
      router.match('fixed-params/:id', 'null#null', {
        params: {
          foo: 'bar'
        }
      });
      router.route('/fixed-params/123');
      expect(params.id).toBe('123');
      return expect(params.foo).toBe('bar');
    });
    return it('should not overwrite fixed parameters', function() {
      router.match('conflicting-params/:foo', 'null#null', {
        params: {
          foo: 'bar'
        }
      });
      router.route('/conflicting-params/123');
      return expect(params.foo).toBe('bar');
    });
  });
});
