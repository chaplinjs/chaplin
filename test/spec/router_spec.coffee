define [
  'backbone'
  'underscore'
  'chaplin/mediator'
  'chaplin/lib/router'
  'chaplin/lib/route'
], (Backbone, _, mediator, Router, Route) ->
  'use strict'

  describe 'Router and Route', ->
    # Initialize shared variables
    router = passedRoute = passedParams = passedOptions = null

    # matchRoute handler to catch the arguments
    matchRoute = (_route, _params, _options) ->
      passedRoute = _route
      passedParams = _params
      passedOptions = _options

    # Create a fresh Router with a fresh Backbone.History before each test
    beforeEach ->
      router = new Router randomOption: 'foo', pushState: false
      Backbone.on 'matchRoute', matchRoute

    afterEach ->
      passedRoute = passedParams = passedOptions = null
      router.dispose()
      Backbone.off 'matchRoute', matchRoute

    it 'should create a Backbone.History instance', ->
      expect(Backbone.history).to.be.a Backbone.History

    it 'should not start the Backbone.History at once', ->
      expect(Backbone.History.started).to.be false

    it 'should allow to start the Backbone.History', ->
      spy = sinon.spy Backbone.history, 'start'
      expect(router.startHistory).to.be.a 'function'
      router.startHistory()
      expect(Backbone.History.started).to.be true
      expect(spy).was.called()

    it 'should default to pushState', ->
      router.startHistory()
      expect(router.options).to.be.an 'object'
      expect(Backbone.history.options.pushState).to.be router.options.pushState

    it 'should pass the options to the Backbone.History instance', ->
      router.startHistory()
      expect(Backbone.history.options.randomOption).to.be 'foo'

    it 'should allow to stop the Backbone.History', ->
      router.startHistory()
      spy = sinon.spy Backbone.history, 'stop'
      expect(router.stopHistory).to.be.a 'function'
      router.stopHistory()
      expect(Backbone.History.started).to.be false
      expect(spy).was.called()

    it 'should have a match method which returns a route', ->
      expect(router.match).to.be.a 'function'
      route = router.match '', 'null#null'
      expect(route).to.be.a Route

    it 'should fire a matchRoute event when a route matches', ->
      spy = sinon.spy()
      Backbone.on 'matchRoute', spy
      router.match '', 'null#null'

      router.route '/'
      expect(spy).was.called()

      Backbone.off 'matchRoute', spy

    it 'should match correctly', ->
      spy = sinon.spy()
      Backbone.on 'matchRoute', spy
      router.match 'correct-match1', 'null#null'
      router.match 'correct-match2', 'null#null'

      routed = router.route '/correct-match1'
      expect(routed).to.be true
      expect(spy.callCount).to.be 1

      Backbone.off 'matchRoute', spy

    it 'should match in order specified when calling router.route', ->
      spy = sinon.spy()
      Backbone.on 'matchRoute', spy
      router.match 'params/:one', 'null#null'
      router.match 'params/:two', 'null#null'

      routed = router.route '/params/1'

      expect(routed).to.be true
      expect(spy.callCount).to.be 1
      expect(passedParams).to.be.an 'object'
      expect(passedParams.one).to.be '1'
      expect(passedParams.two).to.be undefined

      Backbone.off 'matchRoute', spy

    it 'should match in order specified when called by Backbone.History', ->
      spy = sinon.spy()
      Backbone.on 'matchRoute', spy
      router.match 'params/:one', 'null#null'
      router.match 'params/:two', 'null#null'

      router.startHistory()
      routed = Backbone.history.loadUrl '/params/1'

      expect(routed).to.be true
      expect(spy.callCount).to.be 1
      expect(passedParams).to.be.an 'object'
      expect(passedParams.one).to.be '1'
      expect(passedParams.two).to.be undefined

      Backbone.off 'matchRoute', spy

    it 'should allow for registering routes with a name', ->
      router.match 'index', 'null#null', name: 'home'
      router.match 'params/:one', 'null#null', name: 'phonebook'
      router.match 'params/:two', 'null#null', name: 'about'

      names = _.pluck _.pluck(Backbone.history.handlers, 'route'), 'name'
      expect(names).to.eql ['home', 'phonebook', 'about']

    it 'should allow for reversing a route instance to get its url', ->
      named = new Route 'params',
        controller: 'null', action: 'null', name: 'about'

      url = named.reverse()
      expect(url).to.equal 'params'

    it 'should allow for reversing a route instance with object to get its url', ->
      named = new Route 'params/:two',
        controller: 'null', action: 'null', name: 'about'
      url = named.reverse two: 1151
      expect(url).to.equal 'params/1151'

      named = new Route 'params/:two/:one/*other/:another',
        controller: 'null', action: 'null', name: 'about'
      url = named.reverse
        two: 32
        one: 156
        other: 'someone/out/there'
        another: 'meh'
      expect(url).to.equal 'params/32/156/someone/out/there/meh'

    it 'should allow for reversing a route instance with array to get its url', ->
      named = new Route 'params/:two',
        controller: 'null', action: 'null', name: 'about'
      url = named.reverse [1151]
      expect(url).to.equal 'params/1151'

      named = new Route 'params/:two/:one/*other/:another',
        controller: 'null', action: 'null', name: 'about'
      url = named.reverse [32, 156, 'someone/out/there', 'meh']
      expect(url).to.equal 'params/32/156/someone/out/there/meh'

    it 'should reject reversals for regular expressions', ->
      named = new Route /params/, 'null#null', name: 'about'
      url = named.reverse two: 1151
      expect(url).to.be false

    it 'should reject reversals when there are not enough params', ->
      named = new Route 'params/:one/:two',
        controller: 'null', action: 'null', name: 'about'
      expect(-> named.reverse [1]).to.throwError()
      expect(-> named.reverse one: 1).to.throwError()
      expect(-> named.reverse two: 2).to.throwError()

    it 'should allow for reversing a route by its name', ->
      router.match 'index', 'null#null', name: 'home'
      router.match 'phoneparams/:one', 'null#null', name: 'phonebook'
      router.match 'params/:two', 'null#null', name: 'about'

      url = router.reverse 'phonebook', one: 145
      expect(url).to.eql 'phoneparams/145'

    it 'should allow for reversing a route by its name via event', ->
      router.match 'index', 'null#null', name: 'home'
      router.match 'phoneparams/:one', 'null#null', name: 'phonebook'
      router.match 'params/:two', 'null#null', name: 'about'

      url = false
      params = one: 145
      spy = sinon.spy()
      Backbone.trigger '!router:reverse', 'phonebook', params, spy
      expect(spy).was.calledWith 'phoneparams/145'

    it 'should reject reserved controller action names', ->
      for prop in ['constructor', 'initialize', 'redirectTo', 'dispose']
        expect(-> router.match '', "null##{prop}").to.throwError()

    it 'should allow specifying controller and action in options', ->
      delay = (callback) ->
        window.setTimeout callback, 20
      expect(->
        router.match /url/, 'null#null', controller: 'c', action: 'a'
      ).to.throwError()
      expect(->
        router.match /url/, {}
      ).to.throwError()

      url = /url/
      options = {controller: 'c', action: 'a'}
      url2 = /url2/
      options2 = {}

      router.match url, options
      handler = Backbone.history.handlers[0].route
      expect(handler.controller).to.equal 'c'
      expect(handler.action).to.equal 'a'
      expect(handler.url).to.equal options.url

      router.match url2, 'c2#a2', options2
      handler2 = Backbone.history.handlers[1].route
      expect(handler2.controller).to.equal 'c2'
      expect(handler2.action).to.equal 'a2'
      expect(handler2.url).to.equal options2.url

    # Tests for passed route
    # -----------------------

    it 'should pass the route to the matchRoute handler', ->
      router.match 'passing-the-route', 'null#null'
      router.route '/passing-the-route'
      expect(passedRoute).to.be.a Route

    it 'should provide controller and action names on the route', ->
      router.match 'controller/action', 'controller#action'
      router.route '/controller/action'
      expect(passedRoute.controller).to.be 'controller'
      expect(passedRoute.action).to.be 'action'

    # Parameters
    # ----------

    it 'should accept a regular expression as pattern', ->
      router.match /^(\w+)\/(\w+)\/(\w+)$/, 'null#null'
      router.route '/raw/regular/expression'
      expect(passedParams).to.be.an 'object'
      expect(passedParams[0]).to.be 'raw'
      expect(passedParams[1]).to.be 'regular'
      expect(passedParams[2]).to.be 'expression'

    it 'should accept a empty regular expression as catch-all', ->
      router.match '', 'null#null'
      router.match /(?:)/, 'null#null'
      router.route "#{Math.random()}"
      expect(passedParams).to.be.an 'object'
      expect(passedParams).to.be.empty()

    it 'should extract named parameters', ->
      router.match 'params/:one/:p_two_123/three', 'null#null'
      router.route '/params/123-foo/456-bar/three'
      expect(passedParams).to.be.an 'object'
      expect(passedParams.one).to.be '123-foo'
      expect(passedParams.p_two_123).to.be '456-bar'

    it 'should name parameters of a regular expression with `names` option array', ->
      router.match /^params\/(\d+)\/(\w+)$/, 'null#null',
        names: ['one', 'two']
      router.route '/params/123/foo'
      expect(passedParams).to.be.an 'object'
      expect(passedParams.one).to.be '123'
      expect(passedParams.two).to.be 'foo'

    it 'should extract non-ascii named parameters', ->
      router.match 'params/:one/:two/:three/:four', 'null#null'
      router.route "/params/o_O/*.*/ü~ö~ä/#{encodeURIComponent('éêè')}"
      expect(passedParams).to.be.an 'object'
      expect(passedParams.one).to.be 'o_O'
      expect(passedParams.two).to.be '*.*'
      expect(passedParams.three).to.be 'ü~ö~ä'
      expect(passedParams.four).to.be encodeURIComponent('éêè')

    it 'should match splat parameters', ->
      router.match 'params/:one/*two', 'null#null'
      router.route '/params/123-foo/456-bar/789-qux'
      expect(passedParams).to.be.an 'object'
      expect(passedParams.one).to.be '123-foo'
      expect(passedParams.two).to.be '456-bar/789-qux'

    it 'should match splat parameters at the beginning', ->
      router.match 'params/*one/:two', 'null#null'
      router.route '/params/123-foo/456-bar/789-qux'
      expect(passedParams).to.be.an 'object'
      expect(passedParams.one).to.be '123-foo/456-bar'
      expect(passedParams.two).to.be '789-qux'

    it 'should match splat parameters before a named parameter', ->
      router.match 'params/*one:two', 'null#null'
      router.route '/params/123-foo/456-bar/789-qux'
      expect(passedParams).to.be.an 'object'
      expect(passedParams.one).to.be '123-foo/456-bar/'
      expect(passedParams.two).to.be '789-qux'

    it 'should impose constraints', ->
      spy = sinon.spy()
      Backbone.on 'matchRoute', spy
      router.match 'constraints/:id', 'null#null',
        constraints:
          id: /^\d+$/

      router.route '/constraints/123-foo'
      expect(spy).was.notCalled()

      router.route '/constraints/123'
      expect(spy).was.called()

      Backbone.off 'matchRoute', spy

    it 'should pass fixed parameters', ->
      router.match 'fixed-params/:id', 'null#null',
        params:
          foo: 'bar'

      router.route '/fixed-params/123'
      expect(passedParams).to.be.an 'object'
      expect(passedParams.id).to.be '123'
      expect(passedParams.foo).to.be 'bar'

    it 'should not overwrite fixed parameters', ->
      router.match 'conflicting-params/:foo', 'null#null',
        params:
          foo: 'bar'

      router.route '/conflicting-params/123'
      expect(passedParams.foo).to.be 'bar'

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
      expect(passedParams.foo).to.be input.foo
      expect(passedParams.bar).to.be input.bar
      expect(passedParams['q&uu=x']).to.be input['q&uu=x']

    it 'should extract named parameters along with query params', ->
      router.match 'params/:one', 'null#null'
      router.route '/params/named?foo=query123&bar=query_456&qux=789%20query'
      expect(passedParams).to.be.an 'object'
      expect(passedParams.one).to.be 'named'
      expect(passedParams.foo).to.be 'query123'
      expect(passedParams.bar).to.be 'query_456'
      expect(passedParams.qux).to.be '789 query'

    it 'should extract named parameters along with splats', ->
      router.match 'params/*one', 'null#null'
      router.route '/params/foo/bar/qux?foo=query123&bar=query_456&qux=789%20query'
      expect(passedParams).to.be.an 'object'
      expect(passedParams.one).to.be 'foo/bar/qux'
      expect(passedParams.foo).to.be 'query123'
      expect(passedParams.bar).to.be 'query_456'
      expect(passedParams.qux).to.be '789 query'

    # Routing options
    # ---------------

    it 'should pass routing options and add the path', ->
      router.match 'foo', 'null#null'
      path = '/foo'
      options = routingOptions: true
      router.route path, options
      expect(passedParams).to.be.an 'object'
      expect(passedParams).to.be.empty()
      expect(passedOptions).to.eql _.extend(options, {path})

    # Listening to the the !router:route event
    # ----------------------------------------

    it 'should listen to the !router:route event', ->
      path = 'router-route-event'
      options = replace: true, changeURL: true
      callback = sinon.spy()

      routeSpy = sinon.spy router, 'route'
      router.match path, 'router#route'

      Backbone.trigger '!router:route', path, options, callback
      expect(routeSpy).was.calledWith path, options
      expect(callback).was.calledWith true
      expect(passedRoute).to.be.an 'object'
      expect(passedRoute.controller).to.be 'router'
      expect(passedRoute.action).to.be 'route'
      expect(passedOptions).to.eql _.extend(options, {path})

      callback = sinon.spy()
      Backbone.trigger '!router:route', 'different-path', options, callback
      expect(callback).was.calledWith false

      routeSpy.restore()

    it 'should support the old !router:route signature without options', ->
      path = 'router-route-event-old'
      callback = sinon.spy()
      router.match path, 'router#route'

      Backbone.trigger '!router:route', path, callback
      expect(callback).was.calledWith true
      expect(passedRoute).to.be.an 'object'
      expect(passedRoute.controller).to.be 'router'
      expect(passedRoute.action).to.be 'route'
      expect(passedParams).to.be.an 'object'
      expect(passedOptions).to.eql {path, changeURL: true}

    # Listening to the !router:routeByName event
    # ------------------------------------------
    it 'should listen to the !router:routeByName event', ->
      router.match 'index', 'null#null', name: 'home'
      router.match 'phoneparams/:one', 'phonebook#dial', name: 'phonebook'

      routeSpy = sinon.spy router, 'route'

      Backbone.trigger '!router:routeByName', 'phonebook', one: 145
      expect(passedRoute.controller).to.be 'phonebook'
      expect(passedRoute.action).to.be 'dial'
      expect(passedOptions.path).to.be 'phoneparams/145'

    # Listening to the !router:changeURL event
    # ----------------------------------------

    it 'should listen to the !router:changeURL event', ->
      path = 'router-changeurl-event'
      changeURL = sinon.spy router, 'changeURL'

      Backbone.trigger '!router:changeURL', path
      expect(changeURL).was.calledWith path

      changeURL.restore()

    it 'should forward changeURL routing options to Backbone', ->
      path = 'router-changeurl-options'
      changeURL = sinon.spy router, 'changeURL'
      navigate = sinon.stub Backbone.history, 'navigate'

      options = some: 'stuff'
      Backbone.trigger '!router:changeURL', path, options
      expect(navigate).was.calledWith path,
        replace: false, trigger: false

      options = replace: true, trigger: true, some: 'stuff'
      Backbone.trigger '!router:changeURL', path, options
      expect(Backbone.history.navigate).was.calledWith path,
        replace: true, trigger: true

      changeURL.restore()
      navigate.restore()

    # Disposal
    # --------

    it 'should dispose itself correctly', ->
      expect(router.dispose).to.be.a 'function'
      router.dispose()

      # It should stop Backbone.History
      expect(Backbone.History.started).to.be false

      expect(->
        router.match '', 'null#null'
      ).to.throwError()

      expect(->
        router.route '/'
      ).to.throwError()

      expect(router.disposed).to.be true
      if Object.isFrozen
        expect(Object.isFrozen(router)).to.be true

    # Extendability
    # -------------

    it 'should be extendable', ->
      expect(Router.extend).to.be.a 'function'
      expect(Route.extend).to.be.a 'function'

      DerivedRouter = Router.extend()
      derivedRouter = new DerivedRouter()
      expect(derivedRouter).to.be.a Router

      DerivedRoute = Route.extend()
      derivedRoute = new DerivedRoute 'foo', 'foo#bar'
      expect(derivedRoute).to.be.a Route

      derivedRouter.dispose()
