define [
  'mediator', 'lib/router'
], (mediator, Router) ->
  'use strict'

  describe 'Router and Route', ->
    #console.debug 'Router spec'

    router = route = params = undefined

    matchRoute = (_route, _params) ->
      route = _route
      params = _params

    beforeEach ->
      router = new Router()
      mediator.subscribe 'matchRoute', matchRoute

    afterEach ->
      route = params = `undefined`
      mediator.unsubscribe 'matchRoute', matchRoute

    it 'should create a Backbone.History instance', ->
      expect(Backbone.history instanceof Backbone.History).toBe true

    it 'should fire a matchRoute event', ->
      matchRoute = jasmine.createSpy()
      mediator.subscribe 'matchRoute', matchRoute
      router.match '', 'x#y'
      router.route '/'
      expect(matchRoute).toHaveBeenCalled()
      mediator.unsubscribe 'matchRoute', matchRoute

    it 'should match correctly', ->
      matchRoute = jasmine.createSpy()
      mediator.subscribe 'matchRoute', matchRoute
      router.match 'correct-match1', 'null#null'
      router.match 'correct-match2', 'null#null'
      routed = router.route '/correct-match1'
      expect(routed).toBe true
      expect(matchRoute.calls.length).toBe 1
      mediator.unsubscribe 'matchRoute', matchRoute

    it 'should extract URL parameters', ->
      router.match 'params/:one/:p_two_123/three', 'null#null'
      router.route '/params/123-foo/456-bar/three'
      expect(typeof params).toBe 'object'
      expect(params.one).toBe '123-foo'
      expect(params.p_two_123).toBe '456-bar'

    it 'should provide controller name and action', ->
      router.match 'controller/action', 'controller#action'
      router.route '/controller/action'
      expect(typeof route).toBe 'object'
      expect(route.controller).toBe 'controller'
      expect(route.action).toBe 'action'

    it 'should impose constraints', ->
      matchRoute = jasmine.createSpy()
      mediator.subscribe 'matchRoute', matchRoute
      router.match 'constraints/:id', 'null#null',
        constraints:
          id: /^\d+$/

      router.route '/constraints/123-foo'
      expect(matchRoute).not.toHaveBeenCalled()
      router.route '/constraints/123'
      expect(matchRoute).toHaveBeenCalled()
      mediator.unsubscribe 'matchRoute', matchRoute

    it 'should pass fixed parameters', ->
      router.match 'fixed-params/:id', 'null#null',
        params:
          foo: 'bar'

      router.route '/fixed-params/123'
      expect(params.id).toBe '123'
      expect(params.foo).toBe 'bar'

    it 'should not overwrite fixed parameters', ->
      router.match 'conflicting-params/:foo', 'null#null',
        params:
          foo: 'bar'

      router.route '/conflicting-params/123'
      expect(params.foo).toBe 'bar'
