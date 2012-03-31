define(['mediator', 'lib/router'], function (mediator, Router) {
  'use strict';
  describe('Router and Route', function () {
    var router, route, params;
    var matchRoute = function (_route, _params) {
      route = _route;
      params = _params;
    };

    beforeEach(function () {
      router = new Router();
      mediator.subscribe('matchRoute', matchRoute);
    });
    
    afterEach(function () {
      route = params = undefined;
      mediator.unsubscribe('matchRoute', matchRoute);
    });

    it('should create a Backbone.History instance', function () {
      expect(Backbone.history instanceof Backbone.History).toBe(true);
    });

    it('should fire a matchRoute event', function () {
      var matchRoute = jasmine.createSpy();
      mediator.subscribe('matchRoute', matchRoute);
      router.match('', 'x#y');
      router.route('/');
      expect(matchRoute).toHaveBeenCalled();
      mediator.unsubscribe('matchRoute', matchRoute);
    });

    it('should match correctly', function () {
      var matchRoute = jasmine.createSpy();
      mediator.subscribe('matchRoute', matchRoute);
      router.match('correct-match1', 'null#null');
      router.match('correct-match2', 'null#null');
      router.route('/correct-match1');
      expect(matchRoute.calls.length).toBe(1);
      mediator.unsubscribe('matchRoute', matchRoute);
    });

    it('should extract URL parameters', function () {
      router.match('params/:one/:p_two_123/three', 'null#null');
      router.route('/params/123-foo/456-bar/three');
      expect(typeof params).toBe('object');
      expect(params.one).toBe('123-foo');
      expect(params.p_two_123).toBe('456-bar');
    });

    it('should provide controller name and action', function () {
      router.match('controller/action', 'controller#action');
      router.route('/controller/action');
      expect(typeof route).toBe('object');
      expect(route.controller).toBe('controller');
      expect(route.action).toBe('action');
    });

    it('should impose constraints', function () {
      var matchRoute = jasmine.createSpy();
      mediator.subscribe('matchRoute', matchRoute);
      router.match('constraints/:id', 'null#null', {
        constraints: { id: /^\d+$/ }
      });
      router.route('/constraints/123-foo');
      expect(matchRoute).not.toHaveBeenCalled();
      router.route('/constraints/123');
      expect(matchRoute).toHaveBeenCalled();
      mediator.unsubscribe('matchRoute', matchRoute);
    });
    
    it('should pass fixed parameters', function () {
      router.match('fixed-params/:id', 'null#null', {
        params: { foo: 'bar' }
      });
      router.route('/fixed-params/123');
      expect(params.id).toBe('123');
      expect(params.foo).toBe('bar');
    });
    
    it('should not overwrite fixed parameters', function () {
      router.match('conflicting-params/:foo', 'null#null', {
        params: { foo: 'bar' }
      });
      router.route('/conflicting-params/123');
      expect(params.foo).toBe('bar');
    });

  });
});