
define(['mediator', 'lib/router', 'lib/route'], function(mediator, Router, Route) {
  'use strict';  return describe('Router and Route', function() {
    var matchRoute, params, route, router;
    router = route = params = void 0;
    matchRoute = function(_route, _params) {
      route = _route;
      return params = _params;
    };
    beforeEach(function() {
      route = params = void 0;
      if (router) router.deleteHistory();
      router = new Router();
      return mediator.subscribe('matchRoute', matchRoute);
    });
    afterEach(function() {
      return mediator.unsubscribe('matchRoute', matchRoute);
    });
    it('should create a Backbone.History instance', function() {
      return expect(Backbone.history instanceof Backbone.History).toBe(true);
    });
    it('should fire a matchRoute event', function() {
      var spy;
      spy = jasmine.createSpy();
      mediator.subscribe('matchRoute', spy);
      router.match('', 'x#y');
      router.route('/');
      expect(spy).toHaveBeenCalled();
      return mediator.unsubscribe('matchRoute', spy);
    });
    it('should match correctly', function() {
      var routed, spy;
      spy = jasmine.createSpy();
      mediator.subscribe('matchRoute', spy);
      router.match('correct-match1', 'null#null');
      router.match('correct-match2', 'null#null');
      routed = router.route('/correct-match1');
      expect(routed).toBe(true);
      expect(spy.calls.length).toBe(1);
      return mediator.unsubscribe('matchRoute', spy);
    });
    it('should pass the route to the matchRoute handler', function() {
      router.match('passing-the-route', 'null#null');
      router.route('/passing-the-route');
      return expect(route instanceof Route).toBe(true);
    });
    it('should provide controller name and action', function() {
      router.match('controller/action', 'controller#action');
      router.route('/controller/action');
      expect(route.controller).toBe('controller');
      return expect(route.action).toBe('action');
    });
    it('should extract URL parameters', function() {
      router.match('params/:one/:p_two_123/three', 'null#null');
      router.route('/params/123-foo/456-bar/three');
      expect(typeof params).toBe('object');
      expect(params.one).toBe('123-foo');
      return expect(params.p_two_123).toBe('456-bar');
    });
    it('should accept a regular expression as pattern', function() {
      router.match(/^(\w+)\/(\w+)\/(\w+)$/, 'null#null');
      router.route('/raw/regular/expression');
      expect(typeof route).toBe('object');
      expect(typeof params).toBe('object');
      expect(params[0]).toBe('raw');
      expect(params[1]).toBe('regular');
      return expect(params[2]).toBe('expression');
    });
    it('should impose constraints', function() {
      var spy;
      spy = jasmine.createSpy();
      mediator.subscribe('matchRoute', spy);
      router.match('constraints/:id', 'null#null', {
        constraints: {
          id: /^\d+$/
        }
      });
      router.route('/constraints/123-foo');
      expect(spy).not.toHaveBeenCalled();
      router.route('/constraints/123');
      expect(spy).toHaveBeenCalled();
      return mediator.unsubscribe('matchRoute', spy);
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
    it('should not overwrite fixed parameters', function() {
      router.match('conflicting-params/:foo', 'null#null', {
        params: {
          foo: 'bar'
        }
      });
      router.route('/conflicting-params/123');
      return expect(params.foo).toBe('bar');
    });
    return it('should pass query string parameters', function() {
      var input, queryString;
      router.match('query-string', 'null#null');
      input = {
        foo: '123 456',
        'b a r': 'the _quick &brown föx= jumps over the lazy dáwg',
        'q&uu=x': 'the _quick &brown föx= jumps over the lazy dáwg'
      };
      queryString = _(input).reduce(function(memo, val, prop) {
        return memo + (memo === '?' ? '' : '&') + encodeURIComponent(prop) + '=' + encodeURIComponent(val);
      }, '?');
      router.route("query-string" + queryString);
      expect(params.foo).toBe(input.foo);
      expect(params.bar).toBe(input.bar);
      return expect(params['q&uu=x']).toBe(input['q&uu=x']);
    });
  });
});
