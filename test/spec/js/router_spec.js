
define(['underscore', 'mediator', 'chaplin/lib/router', 'chaplin/lib/route'], function(_, mediator, Router, Route) {
  'use strict';  return describe('Router and Route', function() {
    var matchRoute, params, route, router;
    router = route = params = null;
    matchRoute = function(_route, _params) {
      route = _route;
      return params = _params;
    };
    beforeEach(function() {
      router = new Router({
        root: '/test/'
      });
      return mediator.subscribe('matchRoute', matchRoute);
    });
    afterEach(function() {
      route = params = null;
      router.dispose();
      return mediator.unsubscribe('matchRoute', matchRoute);
    });
    it('should create a Backbone.History instance', function() {
      return expect(Backbone.history instanceof Backbone.History).toBe(true);
    });
    it('should not start the Backbone.History at once', function() {
      return expect(Backbone.History.started).toBe(false);
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
    it('should pass query string parameters', function() {
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
    it('should listen to the !router:route event', function() {
      var path, spy;
      path = 'router-route-events';
      spyOn(router, 'route').andCallThrough();
      spy = jasmine.createSpy();
      router.match(path, 'router#route');
      mediator.publish('!router:route', path, spy);
      expect(router.route).toHaveBeenCalledWith(path);
      expect(spy).toHaveBeenCalledWith(true);
      expect(route.controller).toBe('router');
      expect(route.action).toBe('route');
      spy = jasmine.createSpy();
      mediator.publish('!router:route', 'different-path', spy);
      return expect(spy).toHaveBeenCalledWith(false);
    });
    it('should listen to the !router:changeURL event', function() {
      var path;
      path = 'router-changeurl-events';
      spyOn(router, 'changeURL').andCallThrough();
      mediator.publish('!router:changeURL', path);
      return expect(router.changeURL).toHaveBeenCalledWith(path);
    });
    it('should allow to start the Backbone.History', function() {
      var spy;
      spy = spyOn(Backbone.history, 'start').andCallThrough();
      expect(typeof router.startHistory).toBe('function');
      router.startHistory();
      expect(Backbone.History.started).toBe(true);
      return expect(spy).toHaveBeenCalled();
    });
    it('should default to pushState', function() {
      router.startHistory();
      expect(typeof router.options).toBe('object');
      return expect(Backbone.history.options.pushState).toBe(router.options.pushState);
    });
    it('should pass the options to the Backbone.History instance', function() {
      router.startHistory();
      return expect(Backbone.history.options.root).toBe('/test/');
    });
    it('should allow to stop the Backbone.History', function() {
      var spy;
      router.startHistory();
      spy = spyOn(Backbone.history, 'stop').andCallThrough();
      expect(typeof router.stopHistory).toBe('function');
      router.stopHistory();
      expect(Backbone.History.started).toBe(false);
      return expect(spy).toHaveBeenCalled();
    });
    return it('should be disposable', function() {
      expect(typeof router.dispose).toBe('function');
      router.dispose();
      expect(Backbone.history).toBe(void 0);
      expect(function() {
        return router.match('', 'x#y');
      }).toThrow();
      expect(function() {
        return router.route('/');
      }).toThrow();
      expect(router.disposed).toBe(true);
      if (Object.isFrozen) return expect(Object.isFrozen(router)).toBe(true);
    });
  });
});
