import Backbone from 'backbone'
import sinon from 'sinon'
import chai from 'chai'
import sinonChai from 'sinon-chai'
import Chaplin from '../src/chaplin'

chai.use sinonChai
chai.should()

{expect} = require 'chai'
{Route, Router, utils, mediator} = Chaplin

describe 'Router and Route', ->
  # Initialize shared variables
  router = passedRoute = passedParams = passedOptions = null

  # router:match handler to catch the arguments
  routerMatch = (_route, _params, _options) ->
    passedRoute = _route
    passedParams = _params
    passedOptions = _options

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
      expect(Backbone.history).to.be.an.instanceof Backbone.History

    it 'should not start the Backbone.History at once', ->
      expect(Backbone.History.started).to.be.false

    it 'should allow to start the Backbone.History', ->
      spy = sinon.spy Backbone.history, 'start'
      expect(router.startHistory).to.be.a 'function'
      router.startHistory()
      expect(Backbone.History.started).to.be.true
      spy.should.have.been.calledOnce
      spy.restore()

    it 'should default to pushState', ->
      router.startHistory()
      {options} = router
      expect(options).to.be.an 'object'
      expect(Backbone.history.options.pushState).to.equal options.pushState

    it 'should default to root', ->
      router.startHistory()
      {options} = router
      expect(options).to.be.an 'object'
      expect(Backbone.history.options.root).to.equal options.root

    it 'should pass the options to the Backbone.History instance', ->
      router.startHistory()
      expect(Backbone.history.options.randomOption).to.equal 'foo'

    it 'should allow to stop the Backbone.History', ->
      router.startHistory()
      spy = sinon.spy Backbone.history, 'stop'
      expect(router.stopHistory).to.be.a 'function'
      router.stopHistory()
      expect(Backbone.History.started).to.be.false
      spy.should.have.been.calledOnce
      spy.restore()

  describe 'Creating Routes', ->

    it 'should have a match method which returns a route', ->
      expect(router.match).to.be.a 'function'
      route = router.match '', 'null#null'
      expect(route).to.be.an.instanceof Route

    it 'should reject reserved controller action names', ->
      for key in ['constructor', 'initialize', 'redirectTo', 'dispose']
        expect(-> router.match '', "null##{key}").to.throw Error

    it 'should allow specifying controller and action in options', ->
      # Signature: url, 'controller#action', options
      url = 'url'
      options = {}
      router.match url, 'c#a', options
      [{route}] = Backbone.history.handlers
      expect(route.controller).to.equal 'c'
      expect(route.action).to.equal 'a'
      expect(route.url).to.equal options.url

      # Signature: url, { controller, action }
      url = 'url'
      options = controller: 'c', action: 'a'
      router.match url, options
      {route} = Backbone.history.handlers[1]
      expect(route.controller).to.equal 'c'
      expect(route.action).to.equal 'a'
      expect(route.url).to.equal options.url

      # Handle errors
      expect(->
        router.match 'url', 'null#null', controller: 'c', action: 'a'
      ).to.throw Error
      expect(->
        router.match 'url', {}
      ).to.throw Error

    it 'should pass trailing option from Router by default', ->
      url = 'url'
      target = 'c#a'

      route = router.match url, target
      expect(route.options.trailing).to.equal router.options.trailing

      router.options.trailing = true

      route = router.match url, target
      expect(route.options.trailing).to.be.true

      route = router.match url, target, trailing: null
      expect(route.options.trailing).to.be.null

  describe 'Routing', ->

    it 'should fire a router:match event when a route matches', ->
      spy = sinon.spy()
      mediator.subscribe 'router:match', spy
      router.match '', 'null#null'

      router.route url: '/'
      spy.should.have.been.calledOnce

    it 'should match route names, both default and custom', ->
      spy = sinon.spy()
      mediator.subscribe 'router:match', spy
      router.match 'correct-match1', 'controller#action'
      router.match 'correct-match2', 'null#null', name: 'routeName'

      routed1 = router.route 'controller#action'
      routed2 = router.route 'routeName'

      expect(routed1 and routed2).to.be.true
      spy.should.have.been.calledTwice

      mediator.unsubscribe 'router:match', spy

    it 'should match URLs correctly', ->
      spy = sinon.spy()
      mediator.subscribe 'router:match', spy
      router.match 'correct-match1', 'null#null'
      router.match 'correct-match2', 'null#null'

      routed = router.route url: '/correct-match1'
      expect(routed).to.be.true
      spy.should.have.been.calledOnce

      mediator.unsubscribe 'router:match', spy

    it 'should match configuration objects', ->
      spy = sinon.spy()
      mediator.subscribe 'router:match', spy
      router.match 'correct-match', 'null#null'
      router.match 'correct-match-with-name', 'null#null', name: 'null'
      router.match 'correct-match-with/:named_param',
        'null#null', name: 'with-param'

      routed1 = router.route controller: 'null', action: 'null'
      routed2 = router.route name: 'null'

      expect(routed1 and routed2).to.be.true
      spy.should.have.been.calledTwice

      mediator.unsubscribe 'router:match', spy

    it 'should match correctly when using the root option', ->
      subdirRooter = new Router
        randomOption: 'foo', pushState: false, root: '/subdir/'

      spy = sinon.spy()
      mediator.subscribe 'router:match', spy
      subdirRooter.match 'correct-match1', 'null#null'
      subdirRooter.match 'correct-match2', 'null#null'

      routed = subdirRooter.route url: '/subdir/correct-match1'
      expect(routed).to.be.true
      spy.should.have.been.calledOnce

      mediator.unsubscribe 'router:match', spy
      subdirRooter.dispose()

    it 'should match in order specified', ->
      spy = sinon.spy()
      mediator.subscribe 'router:match', spy

      router.match 'params/:one', 'null#null'
      router.match 'params/:two', 'null#null'
      routed = router.route url: '/params/1'

      expect(routed).to.be.true
      spy.should.have.been.calledOnce
      expect(passedParams).to.be.deep.equal {
        one: '1'
      }

      mediator.unsubscribe 'router:match', spy

    it 'should match in order specified when called by Backbone.History', ->
      spy = sinon.spy()
      mediator.subscribe 'router:match', spy
      router.match 'params/:one', 'null#null'
      router.match 'params/:two', 'null#null'

      router.startHistory()
      routed = Backbone.history.loadUrl '/params/1'

      expect(routed).to.be.true
      spy.should.have.been.calledOnce
      expect(passedParams).to.be.deep.equal {
        one: '1'
      }

      mediator.unsubscribe 'router:match', spy

    it 'should identically match URLs that differ only by trailing slash', ->
      router.match 'url', 'null#null'

      routed = router.route url: 'url/'
      expect(routed).to.be.true

      routed = router.route url: 'url/?'
      expect(routed).to.be.true

      routed = router.route url: 'url/?key=val'
      expect(routed).to.be.true

    it 'should leave trailing slash accordingly to current options', ->
      router.match 'url', 'null#null', trailing: null
      routed = router.route url: 'url/'
      expect(routed).to.be.true
      expect(passedRoute).to.be.an 'object'
      expect(passedRoute.path).to.equal 'url/'

    it 'should remove trailing slash accordingly to current options', ->
      router.match 'url', 'null#null', trailing: false
      routed = router.route url: 'url/'
      expect(routed).to.be.true
      expect(passedRoute).to.be.an 'object'
      expect(passedRoute.path).to.equal 'url'

    it 'should add trailing slash accordingly to current options', ->
      router.match 'url', 'null#null', trailing: true
      routed = router.route url: 'url'
      expect(routed).to.be.true
      expect(passedRoute).to.be.an 'object'
      expect(passedRoute.path).to.equal 'url/'

  describe 'Passing the Route', ->

    it 'should pass the route to the router:match handler', ->
      router.match 'passing-the-route', 'controller#action'
      router.route 'controller#action'

      expect(passedRoute).to.be.an 'object'
      expect(passedRoute.path).to.equal 'passing-the-route'
      expect(passedRoute.controller).to.equal 'controller'
      expect(passedRoute.action).to.equal 'action'

    it 'should handle optional parameters', ->
      router.match 'items(/missing/:missing)(/present/:present)',
        'controller#action'
      router.route url: '/items/present/1'

      expect(passedRoute).to.be.an 'object'
      expect(passedRoute.path).to.equal 'items/present/1'
      expect(passedRoute.controller).to.equal 'controller'
      expect(passedRoute.action).to.equal 'action'

  describe 'Passing the Parameters', ->

    it 'should extract named parameters from URL', ->
      router.match 'params/:one/:p_two_123/three', 'null#null'
      router.route url: '/params/123-foo/456-bar/three'
      expect(passedParams).to.deep.equal {
        one: '123-foo'
        p_two_123: '456-bar'
      }

    it 'should extract named parameters from object', ->
      router.match 'params/:one/:p_two_123/three', 'controller#action'
      router.route 'controller#action', one: '123-foo', p_two_123: '456-bar'
      expect(passedParams).to.deep.equal {
        one: '123-foo'
        p_two_123: '456-bar'
      }

    it 'should extract non-ascii named parameters', ->
      router.match 'params/:one/:two/:three/:four', 'null#null'
      router.route url: "/params/o_O/*.*/ü~ö~ä/#{encodeURIComponent 'éêè'}"

      expect(passedParams).to.deep.equal {
        one: 'o_O'
        two: '*.*'
        three: 'ü~ö~ä'
        four: encodeURIComponent 'éêè'
      }

    it 'should match splat parameters', ->
      router.match 'params/:one/*two', 'null#null'
      router.route url: '/params/123-foo/456-bar/789-qux'

      expect(passedParams).to.deep.equal {
        one: '123-foo'
        two: '456-bar/789-qux'
      }

    it 'should match splat parameters at the beginningzr', ->
      router.match 'params/*one/:two', 'null#null'
      router.route url: '/params/123-foo/456-bar/789-qux'

      expect(passedParams).to.deep.equal {
        one: '123-foo/456-bar'
        two: '789-qux'
      }

    it 'should match splat parameters before a named parameter', ->
      router.match 'params/*one:two', 'null#null'
      router.route url: '/params/123-foo/456-bar/789-qux'

      expect(passedParams).to.deep.equal {
        one: '123-foo/456-bar/'
        two: '789-qux'
      }

    it 'should match optional named parameters', ->
      router.match 'items/:type(/page/:page)(/min/:min/max/:max)',
        'null#null'

      router.route url: '/items/clothing'
      expect(passedParams).to.deep.equal {
        type: 'clothing'
        page: undefined
        min: undefined
        max: undefined
      }

      router.route url: '/items/clothing/page/5'
      expect(passedParams).to.deep.equal {
        type: 'clothing'
        page: '5'
        min: undefined
        max: undefined
      }

      router.route url: '/items/clothing/min/10/max/20'
      expect(passedParams).to.deep.equal {
        type: 'clothing'
        page: undefined
        min: '10'
        max: '20'
      }

    it 'should match optional splat parameters', ->
      router.match 'items(/*slug)', 'null#null'

      routed = router.route url: '/items'
      expect(routed).to.be.true
      expect(passedParams).to.deep.equal {
        slug: undefined
      }

      routed = router.route url: '/items/5-boots'
      expect(routed).to.be.true
      expect(passedParams).to.deep.equal {
        slug: '5-boots'
      }

    it 'should pass fixed parameters', ->
      router.match 'fixed-params/:id', 'null#null',
        params:
          foo: 'bar'

      router.route url: '/fixed-params/123'
      expect(passedParams).to.deep.equal {
        id: '123'
        foo: 'bar'
      }

    it 'should not overwrite fixed parameters', ->
      router.match 'conflicting-params/:foo', 'null#null',
        params:
          foo: 'bar'

      router.route url: '/conflicting-params/123'
      expect(passedParams.foo).to.equal 'bar'

    it 'should impose parameter constraints', ->
      spy = sinon.spy()
      mediator.subscribe 'router:match', spy
      router.match 'constraints/:id', 'controller#action',
        constraints:
          id: /^\d+$/

      expect(-> router.route url: '/constraints/1-foo').to.throw Error
      expect(-> router.route 'controller#action', id: '2-foo').to.throw Error

      router.route url: '/constraints/123'
      router.route 'controller#action', id: 123
      spy.should.have.been.calledTwice

      mediator.unsubscribe 'router:match', spy

    it 'should deny regular expression as pattern', ->
      expect(-> router.match /url/, 'null#null').to.throw Error

  describe 'Route Matching', ->

    it 'should not initialize when route name has "#"', ->
      expect(->
        new Route 'params', 'null', 'null', name: 'null#null'
      ).to.throw Error

    it 'should not initialize when using existing controller attr', ->
      expect(->
        new Route 'params', 'null', 'beforeAction'
      ).to.throw Error

    it 'should compare route value', ->
      route = new Route 'params', 'hello', 'world'
      expect(route.matches 'hello#world').to.be.true
      expect(route.matches controller: 'hello', action: 'world').to.be.true
      expect(route.matches name: 'hello#world').to.be.true

      expect(route.matches 'hello#worldz').to.be.false
      expect(route.matches controller: 'hello', action: 'worldz').to.be.false
      expect(route.matches name: 'hello#worldz').to.be.false

  describe 'Route Reversal', ->

    it 'should allow reversing a route instance to get its url', ->
      route = new Route 'params', 'null', 'null'
      url = route.reverse()
      expect(url).to.equal 'params'

    it 'should allow reversing a route instance with object to get its url', ->
      route = new Route 'params/:two', 'null', 'null'
      url = route.reverse two: 1151
      expect(url).to.equal 'params/1151'

      route = new Route 'params/:two/:one/*other/:another', 'null', 'null'
      url = route.reverse
        two: 32
        one: 156
        other: 'someone/out/there'
        another: 'meh'

      expect(url).to.equal 'params/32/156/someone/out/there/meh'

    it 'should allow reversing a route instance with array to get its url', ->
      route = new Route 'params/:two', 'null', 'null'
      url = route.reverse [1151]
      expect(url).to.equal 'params/1151'

      route = new Route 'params/:two/:one/*other/:another', 'null', 'null'
      url = route.reverse [32, 156, 'someone/out/there', 'meh']
      expect(url).to.equal 'params/32/156/someone/out/there/meh'

    it 'should allow reversing optional route params', ->
      route = new Route 'items/:id(/page/:page)(/sort/:sort)', 'null', 'null'
      url = route.reverse id: 5, page: 2, sort: 'price'
      expect(url).to.equal 'items/5/page/2/sort/price'

      route = new Route 'items/:id(/page/:page/sort/:sort)', 'null', 'null'
      url = route.reverse id: 5, page: 2, sort: 'price'
      expect(url).to.equal 'items/5/page/2/sort/price'

    it 'should allow reversing a route instance with optional splats', ->
      route = new Route 'items/:id(-*slug)', 'null', 'null'
      url = route.reverse id: 5, slug: "shirt"
      expect(url).to.equal 'items/5-shirt'

    it 'should handle partial fulfillment of optional portions', ->
      route = new Route 'items/:id(/page/:page)(/sort/:sort)', 'null', 'null'
      url = route.reverse id: 5, page: 2
      expect(url).to.equal 'items/5/page/2'

      route = new Route 'items/:id(/page/:page/sort/:sort)', 'null', 'null'
      url = route.reverse id: 5, page: 2
      expect(url).to.equal 'items/5'

    it 'should handle partial fulfillment of optional splats', ->
      route = new Route 'items/:id(-*slug)(/:section)', 'null', 'null'
      url = route.reverse id: 5, section: 'comments'
      expect(url).to.equal 'items/5/comments'
      url = route.reverse id: 5, slug: 'boots'
      expect(url).to.equal 'items/5-boots'
      url = route.reverse id: 5, slug: 'boots', section: 'comments'
      expect(url).to.equal 'items/5-boots/comments'

      route = new Route 'items/:id(-*slug/:desc)', 'null', 'null'
      url = route.reverse id: 5, slug: 'shirt'
      expect(url).to.equal 'items/5'
      url = route.reverse id: 5, slug: 'shirt', desc: 'brand new'
      expect(url).to.equal 'items/5-shirt/brand new'

    it 'should reject reversals when there are not enough params', ->
      route = new Route 'params/:one/:two', 'null', 'null'
      expect(route.reverse [1]).to.be.false
      expect(route.reverse one: 1).to.be.false
      expect(route.reverse two: 2).to.be.false
      expect(route.reverse()).to.be.false

    it 'should append any extra params as querystring params', ->
      route = new Route 'items/:id', 'null', 'null'
      url = route.reverse id: 23, two: 3
      expect(url).to.equal 'items/23?two=3'

      url = route.reverse {id: 23, two: 3}, {four: 5}
      expect(url).to.match /^items\/23\?/
      expect(utils.queryParams.parse url).to.deep.equal {
        two: '3'
        four: '5'
      }

      url = route.reverse id: 23, two: 3, 'four=5'
      expect(url).to.match /^items\/23\?/
      expect(utils.queryParams.parse url).to.deep.equal {
        two: '3'
        four: '5'
      }

    it 'should not set extra params to query when paramsInQS is false', ->
      route = new Route 'items/:id', 'null', 'null', {paramsInQS: false}
      url = route.reverse id: 23, two: 3
      expect(url).to.equal 'items/23'

    it 'should add trailing slash accordingly to current options', ->
      route = new Route 'params', 'null', 'null', trailing: true
      url = route.reverse()
      expect(url).to.equal 'params/'

  describe 'Router reversing', ->
    register = ->
      router.match 'index', 'null#1', name: 'home'
      router.match 'phone/:one', 'null#2', name: 'phonebook'
      router.match 'params/:two', 'null#2', name: 'about'
      router.match 'fake/:three', 'fake#2', name: 'about'
      router.match 'phone/:four', 'null#a'
      router.match 'users/(:one)', 'null#u1'
      router.match 'users/:one/(:two)', 'null#u2'

    it 'should allow for registering routes with a name', ->
      register()
      names = for handler in Backbone.history.handlers
        handler.route.name

      expect(names).to.deep.equal [
        'home', 'phonebook', 'about',
        'about', 'null#a', 'null#u1', 'null#u2'
      ]

    it 'should allow for reversing a route by its default name', ->
      register()
      url = router.reverse 'null#a', {four: 41}
      expect(url).to.equal '/phone/41'

    it 'should allow for reversing a route by its custom name', ->
      register()
      url = router.reverse 'phonebook', one: 145
      expect(url).to.equal '/phone/145'

      expect(-> router.reverse 'missing', one: 145).to.throw Error

    it 'should report the given criteria if reversal fails', ->
      register()
      expect(-> router.reverse 'missing').to.throw Error

    it 'should allow for reversing a route by its controller', ->
      register()
      url = router.reverse controller: 'null'
      expect(url).to.equal '/index'

    it 'should allow for reversing a route by its controller and action', ->
      register()
      url = router.reverse {controller: 'null', action: '2'}, {two: 41}
      expect(url).to.equal '/params/41'

    it 'should allow for reversing a route by its controller and name', ->
      register()
      url = router.reverse {name: 'about', controller: 'fake'}, {three: 41}
      expect(url).to.equal '/fake/41'

    it 'should allow for reversing a route by its name via event', ->
      register()
      params = one: 145
      spy = sinon.spy()
      url = mediator.execute 'router:reverse', 'phonebook', params
      expect(url).to.equal '/phone/145'

      expect(->
        mediator.execute 'router:reverse', 'missing', params
      ).to.throw Error

    it 'should prepend mount point', ->
      router.dispose()
      mediator.unsubscribe 'router:match', routerMatch

      router = new Router
        randomOption: 'foo', pushState: false, root: '/subdir/'

      mediator.subscribe 'router:match', routerMatch
      register()

      params = one: 145
      url = mediator.execute 'router:reverse', 'phonebook', params
      expect(url).to.equal '/subdir/phone/145'

    it 'should handle optional paramters', ->
      register()

      expect(router.reverse 'null#u1').to.equal '/users'
      expect(router.reverse 'null#u1', one: 'param1').to.equal '/users/param1'
      expect(router.reverse 'null#u1', ['param1']).to.equal '/users/param1'

      expect(router.reverse 'null#u2', one: 'param1').to.equal '/users/param1'
      expect(router.reverse 'null#u2', ['param1']).to.equal '/users/param1'

      url = router.reverse 'null#u2', one: 'param1', two: 'param2'
      expect(url).to.equal '/users/param1/param2'

      url = router.reverse 'null#u2', ['param1', 'param2']
      expect(url).to.equal '/users/param1/param2'

  describe 'Query string extraction', ->

    it 'should extract query string parameters from an url', ->
      router.match 'query-string', 'null#null'

      input =
        foo: '123 456'
        'b a r': 'the _quick &brown föx= jumps over the lazy dáwg'
        'q&uu=x': 'the _quick &brown föx= jumps over the lazy dáwg'
      query = utils.queryParams.stringify input

      router.route url: 'query-string?' + query
      expect(passedOptions.query).to.deep.equal input

    it 'should extract query string parameters from an object', ->
      router.match 'query-string', 'controller#action'

      input =
        foo: '123 456'
        'b a r': 'the _quick &brown föx= jumps over the lazy dáwg'
        'q&uu=x': 'the _quick &brown föx= jumps over the lazy dáwg'

      router.route 'controller#action', null, {query: input}
      expect(passedOptions.query).to.deep.equal input

  describe 'Passing the Routing Options', ->

    it 'should pass routing options', ->
      router.match ':id', 'controller#action'
      query = {x: 32, y: 21}
      options = {query, foo: 123, bar: 456}
      router.route 'controller#action', ['foo'], options

      # It should be a different object
      expect(passedOptions).not.to.equal options
      expect(passedRoute.path).to.equal 'foo'
      expect(passedRoute.query).to.equal 'x=32&y=21'

      expect(passedOptions).to.deep.equal(
        Object.assign {}, options, changeURL: true
      )

  describe 'Setting the router:route handler', ->

    it 'should route when receiving a path', ->
      path = 'router-route-event'
      options = replace: true

      routeSpy = sinon.spy router, 'route'
      router.match path, 'router#route'

      mediator.execute 'router:route', url: path, options
      expect(passedRoute).to.be.an 'object'
      expect(passedRoute.controller).to.equal 'router'
      expect(passedRoute.action).to.equal 'route'
      expect(passedRoute.path).to.equal path
      expect(passedOptions).to.deep.equal(
        Object.assign {}, options, {changeURL: true}
      )

      expect(->
        mediator.execute 'router:route', 'different-path', options
      ).to.throw Error

      routeSpy.restore()

    it 'should route when receiving a name', ->

      router.match '', 'home#index', name: 'home'
      mediator.execute 'router:route', name: 'home'

      expect(passedRoute.controller).to.equal 'home'
      expect(passedRoute.action).to.equal 'index'
      expect(passedRoute.path).to.equal ''
      expect(passedParams).to.be.an 'object'

    it 'should route when receiving both name and params', ->
      router.match 'phone/:id', 'phonebook#dial', name: 'phonebook'

      params = id: '123'
      mediator.execute 'router:route', 'phonebook', params
      expect(passedRoute.controller).to.equal 'phonebook'
      expect(passedRoute.action).to.equal 'dial'
      expect(passedRoute.path).to.equal "phone/#{params.id}"
      expect(passedParams).not.to.equal params
      expect(passedParams).to.deep.equal params

    it 'should route when receiving controller and action name', ->
      router.match '', 'home#index'
      mediator.execute 'router:route', controller: 'home', action: 'index'

      expect(passedRoute.controller).to.equal 'home'
      expect(passedRoute.action).to.equal 'index'
      expect(passedRoute.path).to.equal ''
      expect(passedParams).to.be.an 'object'

    it 'should route when receiving controller and action name and params', ->
      router.match 'phone/:id', 'phonebook#dial'

      params = id: '123'
      mediator.execute 'router:route',
        controller: 'phonebook', action: 'dial', params

      expect(passedRoute.controller).to.equal 'phonebook'
      expect(passedRoute.action).to.equal 'dial'
      expect(passedRoute.path).to.equal "phone/#{params.id}"
      expect(passedParams).not.to.equal params
      expect(passedParams).to.deep.equal params

    it 'should pass options and call the callback', ->
      router.match 'index', 'null#null', name: 'home'
      router.match 'phone/:id', 'phonebook#dial', name: 'phonebook'

      params = id: '123'
      options = replace: true
      mediator.execute 'router:route', 'phonebook', params, options

      expect(passedRoute.controller).to.equal 'phonebook'
      expect(passedRoute.action).to.equal 'dial'
      expect(passedRoute.path).to.equal "phone/#{params.id}"

      expect(passedParams).not.to.equal params
      expect(passedParams).to.deep.equal params

      expect(passedOptions).not.to.equal options
      expect(passedOptions).to.deep.equal(
        Object.assign {}, options, changeURL: true
      )

    it 'should throw an error when no match was found', ->
      expect(->
        mediator.execute 'router:route', 'phonebook'
      ).to.throw Error

  describe 'Changing the URL', ->
    it 'should forward changeURL routing options to Backbone', ->
      path = 'router-changeurl-options'
      changeURL = sinon.spy router, 'changeURL'
      navigate = sinon.spy Backbone.history, 'navigate'
      options = some: 'stuff', changeURL: true

      router.changeURL null, null, {path}, options
      navigate.should.have.been.calledWith path,
        replace: false, trigger: false

      forwarding = replace: true, trigger: true
      router.changeURL null, null, {path},
        Object.assign {}, options, forwarding

      navigate.should.have.been.calledWith path, forwarding
      navigate.restore()

      changeURL.restore()

    it 'should not adjust the URL if not desired', ->
      path = 'router-changeurl-false'
      changeURL = sinon.spy router, 'changeURL'
      navigate = sinon.spy Backbone.history, 'navigate'

      router.changeURL null, null, {path}, changeURL: false
      navigate.should.not.have.been.called

      changeURL.restore()
      navigate.restore()

    it 'should add the query string when adjusting the URL', ->
      path = 'my-little-path'
      query = 'foo=bar'
      changeURL = sinon.spy router, 'changeURL'
      navigate = sinon.spy Backbone.history, 'navigate'

      router.changeURL null, null, {path, query}, changeURL: true
      navigate.should.have.been.calledWith "#{path}?#{query}"

      changeURL.restore()
      navigate.restore()

  describe 'Disposal', ->

    it 'should dispose itself correctly', ->
      expect(router.dispose).to.be.a 'function'
      router.dispose()

      # It should stop Backbone.History
      expect(Backbone.History.started).to.be.false

      expect(->
        router.match '', 'null#null'
      ).to.throw Error

      expect(->
        router.route '/'
      ).to.throw Error

      expect(router.disposed).to.be.true
      expect(router).to.be.frozen

  describe 'Extendability', ->

    it 'should be extendable', ->
      expect(Router.extend).to.be.a 'function'
      expect(Route.extend).to.be.a 'function'

      DerivedRouter = Router.extend()
      derivedRouter = new DerivedRouter()
      expect(derivedRouter).to.be.an.instanceof Router

      DerivedRoute = Route.extend()
      derivedRoute = new DerivedRoute 'foo', 'foo#bar'
      expect(derivedRoute).to.be.an.instanceof Route

      derivedRouter.dispose()
