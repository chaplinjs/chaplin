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
      expect(Backbone.history).to.be.a Backbone.History

    it 'should not start the Backbone.History at once', ->
      expect(Backbone.History.started).to.not.be.ok()

    it 'should allow to start the Backbone.History', ->
      spy = sinon.spy(Backbone.history, 'start')
      expect(router.startHistory).to.be.a 'function'
      router.startHistory()
      expect(Backbone.History.started).to.be.ok()
      expect(spy).was.called()

    it 'should default to pushState', ->
      router.startHistory()
      expect(router.options).to.be.an 'object'
      expect(Backbone.history.options.pushState).to.equal router.options.pushState

    it 'should pass the options to the Backbone.History instance', ->
      router.startHistory()
      expect(Backbone.history.options.randomOption).to.equal 'foo'

    it 'should allow to stop the Backbone.History', ->
      router.startHistory()
      spy = sinon.spy(Backbone.history, 'stop')
      expect(router.stopHistory).to.be.a 'function'
      router.stopHistory()
      expect(Backbone.History.started).to.not.be.ok()
      expect(spy).was.called()

    it 'should fire a matchRoute event when a route matches', ->
      spy = sinon.spy()
      mediator.subscribe 'matchRoute', spy
      router.match '', 'x#y'

      router.route '/'
      expect(spy).was.called()

      mediator.unsubscribe 'matchRoute', spy

    it 'should match correctly', ->
      spy = sinon.spy()
      mediator.subscribe 'matchRoute', spy
      router.match 'correct-match1', 'null#null'
      router.match 'correct-match2', 'null#null'

      routed = router.route '/correct-match1'
      expect(routed).to.be.ok()
      expect(spy.callCount).to.equal 1

      mediator.unsubscribe 'matchRoute', spy

    it 'should match in order specified when calling router.route', ->
      spy = sinon.spy()
      mediator.subscribe 'matchRoute', spy
      router.match 'params/:one', 'null#null'
      router.match 'params/:two', 'null#null'

      routed = router.route '/params/1'

      expect(routed).to.be.ok()
      expect(spy.callCount).to.equal 1
      expect(params.one).to.equal '1'
      expect(params.two).to.equal undefined

      mediator.unsubscribe 'matchRoute', spy

    it 'should match in order specified when called by Backbone.History', ->
      spy = sinon.spy()
      mediator.subscribe 'matchRoute', spy
      router.match 'params/:one', 'null#null'
      router.match 'params/:two', 'null#null'

      router.startHistory()
      routed = Backbone.history.loadUrl '/params/1'

      expect(routed).to.be.ok()
      expect(spy.callCount).to.equal 1
      expect(params.one).to.equal '1'
      expect(params.two).to.equal undefined

      mediator.unsubscribe 'matchRoute', spy

    it 'should reject reserved controller action names', ->
      for prop in ['constructor', 'initialize', 'redirectTo', 'dispose']
        expect(-> router.match '', "null##{prop}").to.throwError()

    it 'should pass the route to the matchRoute handler', ->
      router.match 'passing-the-route', 'null#null'
      router.route '/passing-the-route'
      expect(route).to.be.a Route

    it 'should provide controller name and action', ->
      router.match 'controller/action', 'controller#action'
      router.route '/controller/action'
      expect(route.controller).to.equal 'controller'
      expect(route.action).to.equal 'action'

    it 'should extract URL parameters', ->
      router.match 'params/:one/:p_two_123/three', 'null#null'
      router.route '/params/123-foo/456-bar/three'
      expect(params).to.be.an 'object'
      expect(params.one).to.equal '123-foo'
      expect(params.p_two_123).to.equal '456-bar'

    it 'should extract non-ascii URL parameters', ->
      router.match 'params/:one/:two/:three/:four', 'null#null'
      router.route "/params/o_O/*.*/ü~ö~ä/#{encodeURIComponent('éêè')}"
      expect(params).to.be.an 'object'
      expect(params.one).to.equal 'o_O'
      expect(params.two).to.equal '*.*'
      expect(params.three).to.equal 'ü~ö~ä'
      expect(params.four).to.equal encodeURIComponent('éêè')

    it 'should extract URL path params along with query params', ->
      router.match 'params/:one/:two/:three', 'null#null'
      router.route '/params/123-foo/456-bar/3-three?referrer=mdp'
      expect(params).to.be.an 'object'
      expect(params.one).to.equal '123-foo'
      expect(params.two).to.equal '456-bar'
      expect(params.three).to.equal '3-three'
      expect(params.referrer).to.equal 'mdp'

    it 'should accept a regular expression as pattern', ->
      router.match /^(\w+)\/(\w+)\/(\w+)$/, 'null#null'
      router.route '/raw/regular/expression'
      expect(route).to.be.an 'object'
      expect(params).to.be.an 'object'
      expect(params[0]).to.equal 'raw'
      expect(params[1]).to.equal 'regular'
      expect(params[2]).to.equal 'expression'

    it 'should impose constraints', ->
      spy = sinon.spy()
      mediator.subscribe 'matchRoute', spy
      router.match 'constraints/:id', 'null#null',
        constraints:
          id: /^\d+$/

      router.route '/constraints/123-foo'
      expect(spy).was.notCalled()

      router.route '/constraints/123'
      expect(spy).was.called()

      mediator.unsubscribe 'matchRoute', spy

    it 'should pass fixed parameters', ->
      router.match 'fixed-params/:id', 'null#null',
        params:
          foo: 'bar'

      router.route '/fixed-params/123'
      expect(params.id).to.equal '123'
      expect(params.foo).to.equal 'bar'

    it 'should not overwrite fixed parameters', ->
      router.match 'conflicting-params/:foo', 'null#null',
        params:
          foo: 'bar'

      router.route '/conflicting-params/123'
      expect(params.foo).to.equal 'bar'

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
      expect(params.foo).to.equal input.foo
      expect(params.bar).to.equal input.bar
      expect(params['q&uu=x']).to.equal input['q&uu=x']

    it 'should listen to the !router:route event', ->
      path = 'router-route-events'
      sinon.spy(router, 'route')
      spy = sinon.spy()
      router.match path, 'router#route'

      mediator.publish '!router:route', path, spy
      expect(router.route).was.calledWith path
      expect(spy).was.calledWith true
      expect(route.controller).to.equal 'router'
      expect(route.action).to.equal 'route'

      spy = sinon.spy()
      mediator.publish '!router:route', 'different-path', spy
      expect(spy).was.calledWith false

    it 'should listen to the !router:changeURL event', ->
      path = 'router-changeurl-events'
      sinon.spy(router, 'changeURL')

      mediator.publish '!router:changeURL', path
      expect(router.changeURL).was.calledWith path

    it 'should dispose itself correctly', ->
      expect(router.dispose).to.be.a 'function'
      router.dispose()

      expect(Backbone.history).to.equal undefined

      expect(->
        router.match '', 'x#y'
      ).to.throwError()

      expect(->
        router.route '/'
      ).to.throwError()

      expect(router.disposed).to.be.ok()
      if Object.isFrozen
        expect(Object.isFrozen(router)).to.be.ok()

    it 'should be extendable', ->
      expect(Router.extend).to.be.a 'function'
      # Also test Route
      expect(Route.extend).to.be.a 'function'

      DerivedRouter = Router.extend()
      derivedRouter = new DerivedRouter()
      expect(derivedRouter).to.be.a Router

      DerivedRoute = Route.extend()
      derivedRoute = new DerivedRoute 'foo', 'foo#bar'
      expect(derivedRoute).to.be.a Route

      derivedRouter.dispose()
