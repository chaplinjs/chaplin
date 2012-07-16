define [
  'underscore'
  'chaplin/mediator'
  'chaplin/lib/router'
  'chaplin/lib/route'
], (_, mediator, Router, Route) ->
  'use strict'

  describe 'Router and Route', ->
    #console.debug 'Router spec'

    # Initialize shared variables
    router = route = params = null

    # matchRoute handler to catch the params
    matchRoute = (_route, _params) ->
      route = _route
      params = _params

    # Create a fresh Router with a fresh Backbone.History before each test
    beforeEach ->
      router = new Router randomOption: 'foo'
      mediator.subscribe 'matchRoute', matchRoute

    afterEach ->
      route = params = null
      router.dispose()
      mediator.unsubscribe 'matchRoute', matchRoute

    it 'should create a Backbone.History instance', ->
      expect(Backbone.history instanceof Backbone.History).toBe true

    it 'should not start the Backbone.History at once', ->
      expect(Backbone.History.started).toBe false

    it 'should allow to start the Backbone.History', ->
      spy = spyOn(Backbone.history, 'start').andCallThrough()
      expect(typeof router.startHistory).toBe 'function'
      router.startHistory()
      expect(Backbone.History.started).toBe true
      expect(spy).toHaveBeenCalled()

    it 'should default to pushState', ->
      router.startHistory()
      expect(_.isObject router.options).toBe true
      expect(Backbone.history.options.pushState).toBe router.options.pushState

    it 'should pass the options to the Backbone.History instance', ->
      router.startHistory()
      expect(Backbone.history.options.randomOption).toBe 'foo'

    it 'should allow to stop the Backbone.History', ->
      router.startHistory()
      spy = spyOn(Backbone.history, 'stop').andCallThrough()
      expect(typeof router.stopHistory).toBe 'function'
      router.stopHistory()
      expect(Backbone.History.started).toBe false
      expect(spy).toHaveBeenCalled()

    it 'should fire a matchRoute event when a route matches', ->
      spy = jasmine.createSpy()
      mediator.subscribe 'matchRoute', spy
      router.match '', 'x#y'

      router.route '/'
      expect(spy).toHaveBeenCalled()

      mediator.unsubscribe 'matchRoute', spy

    it 'should match correctly', ->
      spy = jasmine.createSpy()
      mediator.subscribe 'matchRoute', spy
      router.match 'correct-match1', 'null#null'
      router.match 'correct-match2', 'null#null'

      routed = router.route '/correct-match1'
      expect(routed).toBe true
      expect(spy.calls.length).toBe 1

      mediator.unsubscribe 'matchRoute', spy

    it 'should match in order specified when calling router.route', ->
      spy = jasmine.createSpy()
      mediator.subscribe 'matchRoute', spy
      router.match 'params/:one', 'null#null'
      router.match 'params/:two', 'null#null'

      routed = router.route '/params/1'

      expect(routed).toBe true
      expect(spy.calls.length).toBe 1
      expect(params.one).toBe '1'
      expect(params.two).toBe undefined

      mediator.unsubscribe 'matchRoute', spy

    it 'should match in order specified when called by Backbone.History', ->
      spy = jasmine.createSpy()
      mediator.subscribe 'matchRoute', spy
      router.match 'params/:one', 'null#null'
      router.match 'params/:two', 'null#null'

      router.startHistory()
      routed = Backbone.history.loadUrl '/params/1'

      expect(routed).toBe true
      expect(spy.calls.length).toBe 1
      expect(params.one).toBe '1'
      expect(params.two).toBe undefined

      mediator.unsubscribe 'matchRoute', spy

    it 'should reject reserved controller action names', ->
      for prop in ['constructor', 'initialize', 'redirectTo', 'dispose']
        expect(-> router.match '', "null##{prop}").toThrow()

    it 'should pass the route to the matchRoute handler', ->
      router.match 'passing-the-route', 'null#null'
      router.route '/passing-the-route'
      expect(route instanceof Route).toBe true

    it 'should provide controller name and action', ->
      router.match 'controller/action', 'controller#action'
      router.route '/controller/action'
      expect(route.controller).toBe 'controller'
      expect(route.action).toBe 'action'

    it 'should extract URL parameters', ->
      router.match 'params/:one/:p_two_123/three', 'null#null'
      router.route '/params/123-foo/456-bar/three'
      expect(_.isObject params).toBe true
      expect(params.one).toBe '123-foo'
      expect(params.p_two_123).toBe '456-bar'

    it 'should extract non-ascii URL parameters', ->
      router.match 'params/:one/:two/:three/:four', 'null#null'
      router.route "/params/o_O/*.*/ü~ö~ä/#{encodeURIComponent('éêè')}"
      expect(_.isObject params).toBe true
      expect(params.one).toBe 'o_O'
      expect(params.two).toBe '*.*'
      expect(params.three).toBe 'ü~ö~ä'
      expect(params.four).toBe encodeURIComponent('éêè')

    it 'should extract URL path params along with query params', ->
      router.match 'params/:one/:two/:three', 'null#null'
      router.route '/params/123-foo/456-bar/3-three?referrer=mdp'
      expect(_.isObject params).toBe true
      expect(params.one).toBe '123-foo'
      expect(params.two).toBe '456-bar'
      expect(params.three).toBe '3-three'
      expect(params.referrer).toBe 'mdp'

    it 'should accept a regular expression as pattern', ->
      router.match /^(\w+)\/(\w+)\/(\w+)$/, 'null#null'
      router.route '/raw/regular/expression'
      expect(_.isObject route).toBe true
      expect(_.isObject params).toBe true
      expect(params[0]).toBe 'raw'
      expect(params[1]).toBe 'regular'
      expect(params[2]).toBe 'expression'

    it 'should impose constraints', ->
      spy = jasmine.createSpy()
      mediator.subscribe 'matchRoute', spy
      router.match 'constraints/:id', 'null#null',
        constraints:
          id: /^\d+$/

      router.route '/constraints/123-foo'
      expect(spy).not.toHaveBeenCalled()

      router.route '/constraints/123'
      expect(spy).toHaveBeenCalled()

      mediator.unsubscribe 'matchRoute', spy

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

    it 'should pass query string parameters', ->
      router.match 'query-string', 'null#null'

      input =
        foo: '123 456',
        'b a r': 'the _quick &brown föx= jumps over the lazy dáwg'
        'q&uu=x': 'the _quick &brown föx= jumps over the lazy dáwg'
      queryString = _(input).reduce((memo, val, prop) ->
        memo +
        (if memo is '?' then '' else '&') +
        encodeURIComponent(prop) + '=' + encodeURIComponent(val)
      , '?')

      router.route "query-string#{queryString}"
      expect(params.foo).toBe input.foo
      expect(params.bar).toBe input.bar
      expect(params['q&uu=x']).toBe input['q&uu=x']

    it 'should listen to the !router:route event', ->
      path = 'router-route-events'
      spyOn(router, 'route').andCallThrough()
      spy = jasmine.createSpy()
      router.match path, 'router#route'

      mediator.publish '!router:route', path, spy
      expect(router.route).toHaveBeenCalledWith path
      expect(spy).toHaveBeenCalledWith true
      expect(route.controller).toBe 'router'
      expect(route.action).toBe 'route'

      spy = jasmine.createSpy()
      mediator.publish '!router:route', 'different-path', spy
      expect(spy).toHaveBeenCalledWith false

    it 'should listen to the !router:changeURL event', ->
      path = 'router-changeurl-events'
      spyOn(router, 'changeURL').andCallThrough()

      mediator.publish '!router:changeURL', path
      expect(router.changeURL).toHaveBeenCalledWith path

    it 'should dispose itself correctly', ->
      expect(typeof router.dispose).toBe 'function'
      router.dispose()

      expect(Backbone.history).toBe undefined

      expect(->
        router.match '', 'x#y'
      ).toThrow()

      expect(->
        router.route '/'
      ).toThrow()

      expect(router.disposed).toBe true
      if Object.isFrozen
        expect(Object.isFrozen(router)).toBe true

    it 'should be extendable', ->
      expect(typeof Router.extend).toBe 'function'
      # Also test Route
      expect(typeof Route.extend).toBe 'function'

      DerivedRouter = Router.extend()
      derivedRouter = new DerivedRouter()
      expect(derivedRouter instanceof Router).toBe true

      DerivedRoute = Route.extend()
      derivedRoute = new DerivedRoute 'foo', 'foo#bar'
      expect(derivedRoute instanceof Route).toBe true

      derivedRouter.dispose()
