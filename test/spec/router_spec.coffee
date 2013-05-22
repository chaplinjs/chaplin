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

    # Serialize pairs into query string (without leading question mark)
    serializequery = (pairs) ->
      _.reduce(pairs, (memo, val, prop) ->
        memo +
        (if memo is '' then '' else '&') +
        encodeURIComponent(prop) + '=' + encodeURIComponent(val)
      , '')

    # router:match handler to catch the arguments
    routerMatch = (_route, _params, _options) ->
      passedRoute = _route
      passedParams = _params
      passedOptions = _options

    # Helper for creating params/options to compare with
    create = ->
      _.extend {}, arguments...

    # Create a fresh Router with a fresh Backbone.History before each test
    beforeEach ->
      router = new Router randomOption: 'foo', pushState: false
      mediator.subscribe 'router:match', routerMatch

    afterEach ->
      passedRoute = passedParams = passedOptions = null
      router.dispose()
      mediator.unsubscribe 'router:match', routerMatch

    describe 'Interaction with Backbone.History', ->

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
        spy.restore()

      it 'should default to pushState', ->
        router.startHistory()
        expect(router.options).to.be.an 'object'
        expect(Backbone.history.options.pushState).to.be router.options.pushState

      it 'should default to root', ->
        router.startHistory()
        expect(router.options).to.be.an 'object'
        expect(Backbone.history.options.root).to.be router.options.root

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
        spy.restore()

    describe 'Creating Routes', ->

      it 'should have a match method which returns a route', ->
        expect(router.match).to.be.a 'function'
        route = router.match '', 'null#null'
        expect(route).to.be.a Route

      it 'should reject reserved controller action names', ->
      for prop in ['constructor', 'initialize', 'redirectTo', 'dispose']
        expect(-> router.match '', "null##{prop}").to.throwError()

      it 'should allow specifying controller and action in options', ->
        # Signature: url, 'controller#action', options
        url = 'url'
        options = {}
        router.match url, 'c#a', options
        route = Backbone.history.handlers[0].route
        expect(route.controller).to.be 'c'
        expect(route.action).to.be 'a'
        expect(route.url).to.be options.url

        # Signature: url, { controller, action }
        url = 'url'
        options = controller: 'c', action: 'a'
        router.match url, options
        route = Backbone.history.handlers[1].route
        expect(route.controller).to.be 'c'
        expect(route.action).to.be 'a'
        expect(route.url).to.be options.url

        # Handle errors
        expect(->
          router.match 'url', 'null#null', controller: 'c', action: 'a'
        ).to.throwError()
        expect(->
          router.match 'url', {}
        ).to.throwError()

    describe 'Routing', ->

      it 'should fire a router:match event when a route matches', ->
        spy = sinon.spy()
        mediator.subscribe 'router:match', spy
        router.match '', 'null#null'

        router.route '/'
        expect(spy).was.called()

      it 'should match correctly', ->
        spy = sinon.spy()
        mediator.subscribe 'router:match', spy
        router.match 'correct-match1', 'null#null'
        router.match 'correct-match2', 'null#null'

        routed = router.route '/correct-match1'
        expect(routed).to.be true
        expect(spy).was.calledOnce()

        mediator.unsubscribe 'router:match', spy

      it 'should match correctly when using the root option', ->
        subdirRooter = new Router randomOption: 'foo', pushState: false, root: '/subdir/'
        spy = sinon.spy()
        mediator.subscribe 'router:match', spy
        subdirRooter.match 'correct-match1', 'null#null'
        subdirRooter.match 'correct-match2', 'null#null'

        routed = subdirRooter.route '/subdir/correct-match1'
        expect(routed).to.be true
        expect(spy).was.calledOnce()

        mediator.unsubscribe 'router:match', spy
        subdirRooter.dispose()

      it 'should match in order specified', ->
        spy = sinon.spy()
        mediator.subscribe 'router:match', spy
        router.match 'params/:one', 'null#null'
        router.match 'params/:two', 'null#null'

        routed = router.route '/params/1'

        expect(routed).to.be true
        expect(spy).was.calledOnce()
        expect(passedParams).to.be.an 'object'
        expect(passedParams.one).to.be '1'
        expect(passedParams.two).to.be undefined

        mediator.unsubscribe 'router:match', spy

      it 'should match in order specified when called by Backbone.History', ->
        spy = sinon.spy()
        mediator.subscribe 'router:match', spy
        router.match 'params/:one', 'null#null'
        router.match 'params/:two', 'null#null'

        router.startHistory()
        routed = Backbone.history.loadUrl '/params/1'

        expect(routed).to.be true
        expect(spy).was.calledOnce()
        expect(passedParams).to.be.an 'object'
        expect(passedParams.one).to.be '1'
        expect(passedParams.two).to.be undefined

        mediator.unsubscribe 'router:match', spy

    describe 'Passing the Route', ->

      it 'should pass the route to the router:match handler', ->
        router.match 'passing-the-route', 'controller#action'
        router.route '/passing-the-route'
        expect(passedRoute).to.be.an 'object'
        expect(passedRoute.path).to.be 'passing-the-route'
        expect(passedRoute.controller).to.be 'controller'
        expect(passedRoute.action).to.be 'action'

    describe 'Passing the Parameters', ->

      it 'should extract named parameters', ->
        router.match 'params/:one/:p_two_123/three', 'null#null'
        router.route '/params/123-foo/456-bar/three'
        expect(passedParams).to.be.an 'object'
        expect(passedParams.one).to.be '123-foo'
        expect(passedParams.p_two_123).to.be '456-bar'

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

      it 'should impose parameter constraints', ->
        spy = sinon.spy()
        mediator.subscribe 'router:match', spy
        router.match 'constraints/:id', 'null#null',
          constraints:
            id: /^\d+$/

        router.route '/constraints/123-foo'
        expect(spy).was.notCalled()

        router.route '/constraints/123'
        expect(spy).was.called()

        mediator.unsubscribe 'router:match', spy

      it 'should deny regular expression as pattern', ->
        expect(-> router.match /url/, 'null#null').to.throwError()

    describe 'Route Matching', ->

      it 'should not initialize when route name has "#"', ->
        expect(->
          new Route 'params', 'null', 'null', name: 'null#null'
        ).to.throwError()
      it 'should not initialize when using existing controller attr', ->
        expect(->
          new Route 'params', 'null', 'beforeAction'
        ).to.throwError()

      it 'should compare route value', ->
        route = new Route 'params', 'hello', 'world'
        expect(route.matches 'hello#world').to.be true
        expect(route.matches controller: 'hello', action: 'world').to.be true
        expect(route.matches name: 'hello#world').to.be true

        expect(route.matches 'hello#worldz').to.be false
        expect(route.matches controller: 'hello', action: 'worldz').to.be false
        expect(route.matches name: 'hello#worldz').to.be false

    describe 'Route Reversal', ->

      it 'should allow for reversing a route instance to get its url', ->
        route = new Route 'params', 'null', 'null'
        url = route.reverse()
        expect(url).to.be 'params'

      it 'should allow for reversing a route instance with object to get its url', ->
        route = new Route 'params/:two', 'null', 'null'
        url = route.reverse two: 1151
        expect(url).to.be 'params/1151'

        route = new Route 'params/:two/:one/*other/:another', 'null', 'null'
        url = route.reverse
          two: 32
          one: 156
          other: 'someone/out/there'
          another: 'meh'
        expect(url).to.be 'params/32/156/someone/out/there/meh'

      it 'should allow for reversing a route instance with array to get its url', ->
        route = new Route 'params/:two', 'null', 'null'
        url = route.reverse [1151]
        expect(url).to.be 'params/1151'

        route = new Route 'params/:two/:one/*other/:another', 'null', 'null'
        url = route.reverse [32, 156, 'someone/out/there', 'meh']
        expect(url).to.be 'params/32/156/someone/out/there/meh'

      it 'should reject reversals when there are not enough params', ->
        route = new Route 'params/:one/:two', 'null', 'null'
        expect(route.reverse [1]).to.eql false
        expect(route.reverse one: 1).to.eql false
        expect(route.reverse two: 2).to.eql false

    describe 'Router reversing', ->
      register = ->
        router.match 'index', 'null#1', name: 'home'
        router.match 'phone/:one', 'null#2', name: 'phonebook'
        router.match 'params/:two', 'null#2', name: 'about'
        router.match 'fake/:three', 'fake#2', name: 'about'
        router.match 'phone/:four', 'null#a'

      it 'should allow for registering routes with a name', ->
        register()
        names = _.pluck _.pluck(Backbone.history.handlers, 'route'), 'name'
        expect(names).to.eql ['home', 'phonebook', 'about', 'about', 'null#a']

      it 'should allow for reversing a route by its default name', ->
        register()
        url = router.reverse 'null#a', {four: 41}
        expect(url).to.be '/phone/41'

      it 'should allow for reversing a route by its custom name', ->
        register()
        url = router.reverse 'phonebook', one: 145
        expect(url).to.be '/phone/145'

        url = router.reverse 'missing', one: 145
        expect(url).to.be false

      it 'should allow for reversing a route by its controller', ->
        register()
        url = router.reverse controller: 'null'
        expect(url).to.be '/index'

      it 'should allow for reversing a route by its controller and action', ->
        register()
        url = router.reverse {controller: 'null', action: '2'}, {two: 41}
        expect(url).to.be '/params/41'

      it 'should allow for reversing a route by its controller and name', ->
        register()
        url = router.reverse {name: 'about', controller: 'fake'}, {three: 41}
        expect(url).to.be '/fake/41'

      it 'should allow for reversing a route by its name via event', ->
        register()
        params = one: 145
        spy = sinon.spy()
        mediator.publish '!router:reverse', 'phonebook', params, spy
        expect(spy).was.calledWith '/phone/145'

        spy = sinon.spy()
        mediator.publish '!router:reverse', 'missing', params, spy
        expect(spy).was.calledWith false

      it 'should prepend mount point', ->
        router.dispose()
        mediator.unsubscribe 'router:match', routerMatch

        router = new Router randomOption: 'foo', pushState: false, root: '/subdir/'
        mediator.subscribe 'router:match', routerMatch
        register()

        params = one: 145
        spy = sinon.spy()
        mediator.publish '!router:reverse', 'phonebook', params, spy
        expect(spy).was.calledWith '/subdir/phone/145'

    describe 'Query string extraction', ->

      it 'should extract query string parameters', ->
        router.match 'query-string', 'null#null'

        input =
          foo: '123 456'
          'b a r': 'the _quick &brown föx= jumps over the lazy dáwg'
          'q&uu=x': 'the _quick &brown föx= jumps over the lazy dáwg'
        query = serializequery input

        router.route 'query-string', {query}
        expect(passedParams).to.eql input

      it 'should extract query string params along with named', ->
        router.match 'query-string/:one', 'null#null'

        input =
          foo: 'query123'
          bar: 'query_456'
          qux: '789 query'
          one: 'whatever'
        query = serializequery input

        router.route '/query-string/named', {query}
        # Named params overwrite query string params
        expect(passedParams).to.eql create(input, one: 'named')

      it 'should extract query string params along with splats', ->
        router.match 'query-string/*one', 'null#null'

        input =
          foo: 'query123'
          bar: 'query_456'
          qux: '789 query'
          one: 'whatever'
        query = serializequery input

        router.route '/query-string/foo/bar/qux', {query}
        # Named params overwrite query string params
        expect(passedParams).to.eql create(input, one: 'foo/bar/qux')

      it 'should use the current query string as fallback', ->
        input =
          foo: 'query123'
          bar: 'query_456'
          qux: '789 query'
        query = serializequery input

        # We need to know this implementation detail to stub it correctly
        stub = sinon.stub(Route.prototype, 'getCurrentQuery')
          .returns(query)

        router.match 'query-string', 'null#null'
        router.route '/query-string'

        expect(stub).was.called()
        expect(passedParams).to.eql input

        stub.restore()

    describe 'Passing the Routing Options', ->

      it 'should pass routing options', ->
        router.match ':id', 'null#null'
        path = '/foo'
        query = 'x=32&y=21'
        options = foo: 123, bar: 456
        router.route path, create {query}, options
        # It should be a different object
        expect(passedOptions).not.to.be options
        expect(passedRoute.query).to.be query
        expect(passedOptions).to.eql(
          create(options, changeURL: true)
        )

    describe 'Listening to the the !router:route event', ->

      it 'should listen to the !router:route event', ->
        path = 'router-route-event'
        options = replace: true
        callback = sinon.spy()

        routeSpy = sinon.spy router, 'route'
        router.match path, 'router#route'

        mediator.publish '!router:route', path, options, callback
        expect(routeSpy).was.calledWith path, options
        expect(callback).was.calledWith true
        expect(passedRoute).to.be.an 'object'
        expect(passedRoute.controller).to.be 'router'
        expect(passedRoute.action).to.be 'route'
        expect(passedRoute.path).to.be path
        expect(passedOptions).to.eql(
          create(options, {changeURL: true})
        )

        callback = sinon.spy()
        mediator.publish '!router:route', 'different-path', options, callback
        expect(callback).was.calledWith false

        routeSpy.restore()

      it 'should support the old !router:route signature without options', ->
        path = 'router-route-event-old'
        callback = sinon.spy()
        router.match path, 'router#route'

        mediator.publish '!router:route', path, callback
        expect(callback).was.calledWith true
        expect(passedRoute).to.be.an 'object'
        expect(passedRoute.controller).to.be 'router'
        expect(passedRoute.action).to.be 'route'
        expect(passedRoute.path).to.be path
        expect(passedParams).to.be.an 'object'
        expect(passedOptions).to.eql {changeURL: true}

    describe 'Routing by Name', ->

      it 'should listen to the !router:routeByName event', ->

        router.match '', 'home#index', name: 'home'
        mediator.publish '!router:routeByName', 'home'

        expect(passedRoute.controller).to.be 'home'
        expect(passedRoute.action).to.be 'index'
        expect(passedRoute.path).to.be ''
        expect(passedParams).to.be.an 'object'

      it 'should route by name and params', ->
        router.match '', 'home#index', name: 'home'
        router.match 'phone/:id', 'phonebook#dial', name: 'phonebook'

        params = id: '123'
        mediator.publish '!router:routeByName', 'phonebook', params
        expect(passedRoute.controller).to.be 'phonebook'
        expect(passedRoute.action).to.be 'dial'
        expect(passedRoute.path).to.be "phone/#{params.id}"
        expect(passedParams).not.to.be params
        expect(passedParams).to.be.an 'object'
        expect(passedParams.id).to.be params.id

      it 'should pass options and call the callback', ->
        router.match 'index', 'null#null', name: 'home'
        router.match 'phone/:id', 'phonebook#dial', name: 'phonebook'

        routeSpy = sinon.spy router, 'route'
        callbackSpy = sinon.spy()

        params = id: '123'
        options = replace: true
        mediator.publish '!router:routeByName', 'phonebook',
          params, options, callbackSpy

        expectedPath = "/phone/#{params.id}"
        expect(routeSpy).was.calledWith expectedPath, options
        expect(callbackSpy).was.calledWith true

        expect(passedRoute.controller).to.be 'phonebook'
        expect(passedRoute.action).to.be 'dial'
        expect(passedRoute.path).to.be expectedPath[1..]
        expect(passedParams).not.to.be params
        expect(passedParams).to.be.an 'object'
        expect(passedParams.id).to.be params.id
        expect(passedOptions).not.to.be options
        expect(passedOptions).to.eql(
          create(options, options,
            changeURL: true
          )
        )

      it 'should pass false to the callback when no named route was found', ->
        callbackSpy = sinon.spy()
        params = {}
        options = {}
        mediator.publish '!router:routeByName', 'phonebook',
          params, options, callbackSpy
        expect(callbackSpy).was.calledWith false

    describe 'Changing the URL', ->

      it 'should listen to the !router:changeURL event', ->
        path = 'router-changeurl-event'
        changeURL = sinon.spy router, 'changeURL'

        mediator.publish '!router:changeURL', path
        expect(changeURL).was.calledWith path

        changeURL.restore()

      it 'should forward changeURL routing options to Backbone', ->
        path = 'router-changeurl-options'
        changeURL = sinon.spy router, 'changeURL'
        navigate = sinon.stub Backbone.history, 'navigate'

        options = some: 'stuff'
        mediator.publish '!router:changeURL', path, options
        expect(navigate).was.calledWith path,
          replace: false, trigger: false

        options = replace: true, trigger: true, some: 'stuff'
        mediator.publish '!router:changeURL', path, options
        expect(Backbone.history.navigate).was.calledWith path,
          replace: true, trigger: true

        changeURL.restore()
        navigate.restore()

    describe 'Disposal', ->

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

    describe 'Extendability', ->

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
