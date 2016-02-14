'use strict'

{uniqueId} = require 'underscore'

sinon = require 'sinon'
chai = require 'chai'
chai.use require 'sinon-chai'
chai.should()

{expect} = require 'chai'
{Composer, Controller, Dispatcher, mediator} = require '../src/chaplin'

describe 'Dispatcher', ->
  # Initialize shared variables
  dispatcher = params = path = options = stdOptions = route1 = route2 =
    redirectToURLRoute = redirectToControllerRoute = composer = null

  # Default options which are added on first dispatching

  addedOptions =
    forceStartup: false

  # Test controllers

  class Test1Controller extends Controller
    initialize: (params, options) ->
      #console.debug 'Test1Controller#initialize', params, options
      super

    show: (params, options) ->
      #console.debug 'Test1Controller#show', params, options

    redirectToURL: (params, options) ->
      @redirectTo '/test/123'

    dispose: (params, newControllerName) ->
      #console.debug 'Test1Controller#dispose'
      super

  class Test2Controller extends Controller
    initialize: (params, options) ->
      #console.debug 'Test2Controller#initialize', params, options
      super

    show: (params, options) ->
      #console.debug 'Test2Controller#show', params, options

    dispose: (params, newControllerName) ->
      #console.debug 'Test2Controller#dispose'
      super

  loadStub = sinon.stub Dispatcher.prototype, 'loadController'

  makeLoadController = (name, controller) ->
    loadStub.withArgs(name).callsArgWith 1, controller

  makeLoadController 'test1', Test1Controller
  makeLoadController 'test2', Test2Controller

  # Shortcut for publishing router:match events
  publishMatch = ->
    mediator.publish 'router:match', arguments...

  # Reset helper: Create fresh params and options
  refreshParams = ->
    params = id: uniqueId 'paramsId'
    path = "test/#{params.id}"
    options = {}
    stdOptions = Object.assign {}, addedOptions, query: {}

    # Fake route objects, walk like a route and swim like a route
    route1 = {controller: 'test1', action: 'show', path}
    route2 = {controller: 'test2', action: 'show', path}
    redirectToURLRoute =
      {controller: 'test1', action: 'redirectToURL', path}
    redirectToControllerRoute =
      {controller: 'test1', action: 'redirectToController', path}

  # Register before/after handlers

  beforeEach ->
    # Create a fresh Dispatcher instance for each test
    dispatcher = new Dispatcher()
    refreshParams()

  afterEach ->
    if dispatcher
      dispatcher.dispose()
      dispatcher = null

  after ->
    loadStub.restore()

  # The Tests

  it 'should dispatch routes to controller actions', ->
    proto = Test1Controller.prototype
    initialize = sinon.spy proto, 'initialize'
    action = sinon.spy proto, 'show'

    publishMatch route1, params, options

    for spy in [initialize, action]
      spy.should.have.been.calledOnce
      expect(spy.firstCall.thisValue).to.be.an.instanceof Test1Controller

      [passedParams, passedRoute, passedOptions] = spy.firstCall.args

      expect(passedParams).to.deep.equal params
      expect(passedRoute).to.deep.equal route1
      expect(passedOptions).to.deep.equal stdOptions

      initialize.restore()
      action.restore()

  it 'should not start the same controller if params match', ->
    publishMatch route1, params, options

    proto = Test1Controller.prototype
    initialize = sinon.spy proto, 'initialize'
    action = sinon.spy proto, 'show'

    publishMatch route1, params,
      Object.assign {}, options, query: {}

    initialize.should.not.have.been.called
    initialize.restore()

    action.should.not.have.been.called
    action.restore()

  it 'should start the same controller if params differ', ->
    proto = Test1Controller.prototype
    initialize = sinon.spy proto, 'initialize'
    action = sinon.spy proto, 'show'

    paramsStore = []
    optionsStore = []

    for i in [0..1]
      refreshParams()
      paramsStore.push params
      optionsStore.push options
      publishMatch route1, params, options

    initialize.should.have.been.calledTwice
    action.should.have.been.calledTwice

    for i in [0..1]
      for spy in [initialize, action]
        [passedParams, passedRoute, passedOptions] = spy.args[i]

        expect(passedOptions).to.deep.equal stdOptions
        expect(passedParams).to.deep.equal paramsStore[i]
        expect(passedRoute.controller).to.equal route1.controller
        expect(passedRoute.action).to.equal route1.action

        if i is 1
          expect(passedRoute.previous.controller).to.equal route1.controller

    initialize.restore()
    action.restore()

  it 'should start the same controller if query parameters differ', ->
    proto = Test1Controller.prototype
    initialize = sinon.spy proto, 'initialize'
    action = sinon.spy proto, 'show'

    optionsStore = [
      {query: key: 'a'}
      {query: key: 'b'}
    ]

    publishMatch route1, params, optionsStore[0]
    publishMatch route1, params, optionsStore[1]

    initialize.should.have.been.calledTwice
    action.should.have.been.calledTwice

    for i in [0..1]
      for spy in [initialize, action]
        [passedParams, passedRoute, passedOptions] = spy.args[i]

        options = Object.assign {}, stdOptions, optionsStore[i]
        expect(passedOptions).to.deep.equal options
        expect(passedParams).to.deep.equal params
        expect(passedRoute.controller).to.equal route1.controller
        expect(passedRoute.action).to.equal route1.action

        if i is 1
          expect(passedRoute.previous.controller).to.equal route1.controller

    initialize.restore()
    action.restore()

  it 'should start the same controller if forced', ->
    proto = Test1Controller.prototype
    initialize = sinon.spy proto, 'initialize'
    action = sinon.spy proto, 'show'

    paramsStore = []
    optionsStore = []

    for i in [0..1]
      refreshParams()
      paramsStore.push params
      optionsStore.push options
      options.forceStartup = i is 1
      publishMatch route1, params, options

    for i in [0..1]
      for spy in [initialize, action]
        [passedParams, passedRoute, passedOptions] = spy.args[i]

        expect(passedParams).to.deep.equal paramsStore[i]
        expect(passedRoute.controller).to.equal route1.controller
        expect(passedRoute.action).to.equal route1.action

        expect(passedOptions).to.deep.equal Object.assign {},
          stdOptions, optionsStore[i], { forceStartup: i isnt 0 }

      initialize.restore()
      action.restore()

  it 'should save the controller, action, params, query and path', ->
    publishMatch route1, params, options

    options1 = Object.assign {}, options, {query: key: 'a'}
    publishMatch route2, params, options1

    # Check that previous route is saved
    d = dispatcher
    expect(d.previousRoute.controller).to.equal 'test1'
    expect(d.currentController).to.be.an.instanceof Test2Controller
    expect(d.currentParams).to.deep.equal params
    expect(d.currentQuery).to.deep.equal options1.query
    expect(d.currentRoute).to.deep.equal Object.assign {}, route2,
      {previous: Object.assign {}, route1, {params}}

  it 'should add the previous controller name to the route', ->
    action = sinon.spy Test2Controller.prototype, 'show'

    publishMatch route1, params, options
    publishMatch route2, params, options

    action.should.have.been.calledOnce
    route = action.firstCall.args[1]
    expect(route.controller).to.equal route2.controller
    expect(route.action).to.equal route2.action
    expect(route.previous).to.be.an 'object'
    expect(route.previous.controller).to.equal route1.controller
    expect(route.previous.action).to.equal route1.action

    action.restore()

  it 'should dispose inactive controllers', ->
    dispose = sinon.spy Test1Controller.prototype, 'dispose'
    publishMatch route1, params, options
    publishMatch route2, params, options

    # It should pass the params and the new controller name
    dispose.should.have.been.calledOnce
    [passedParams, passedRoute] = dispose.firstCall.args
    expect(passedParams).to.deep.equal params
    expect(passedRoute.controller).to.equal route2.controller
    expect(passedRoute.action).to.equal route2.action
    expect(passedRoute.path).to.equal route2.path

    dispose.restore()

  it 'should fire beforeControllerDispose events', ->
    publishMatch route1, params, options

    beforeControllerDispose = sinon.spy()
    mediator.subscribe 'beforeControllerDispose', beforeControllerDispose

    # Now route to Test2Controller
    publishMatch route2, params, options
    beforeControllerDispose.should.have.been.calledOnce

    # Event payload should be the now disposed controller
    [passedController] = beforeControllerDispose.firstCall.args
    expect(passedController).to.be.an.instanceof Test1Controller
    expect(passedController.disposed).to.be.true

    mediator.unsubscribe 'beforeControllerDispose', beforeControllerDispose

  it 'should publish dispatch events', ->
    dispatch = sinon.spy()
    mediator.subscribe 'dispatcher:dispatch', dispatch

    publishMatch route1, params, options
    publishMatch route2, params, options

    dispatch.should.have.been.calledTwice

    for i in [0..1]
      {args} = dispatch.getCall i
      expect(args).to.have.lengthOf 4
      [passedController, passedParams, passedRoute, passedOptions] = args

      expect(passedController).to.be.an.instanceof(
        if i is 0 then Test1Controller else Test2Controller
      )
      expect(passedRoute.controller).to.equal(
        if i is 0 then 'test1' else 'test2'
      )

      expect(passedParams).to.deep.equal params
      expect(passedOptions).to.deep.equal stdOptions
      expect(passedRoute.action).to.equal 'show'

      if i is 0
        expect(passedRoute.previous).to.be.undefined
      else
        expect(passedRoute.previous.controller).to.equal 'test1'

    mediator.unsubscribe 'dispatcher:dispatch', dispatch

  it 'should support redirection to an URL', ->
    dispatch = sinon.spy()
    routed = sinon.spy()
    mediator.subscribe 'dispatcher:dispatch', dispatch
    mediator.subscribe 'router:route', routed

    route = sinon.spy()
    mediator.setHandler 'router:route', route

    # Dispatch a route to check if previous controller info is correct after
    # redirection
    publishMatch route1, params, options

    # Open another route that redirects somewhere
    refreshParams()
    actionName = 'redirectToURL'
    action = sinon.spy Test1Controller.prototype, actionName
    publishMatch redirectToURLRoute, params, options

    action.should.have.been.calledOnce
    [passedParams, passedRoute, passedOptions] = action.firstCall.args
    expect(passedParams).to.deep.equal params
    expect(passedRoute.previous.controller).to.equal 'test1'
    expect(passedOptions).to.deep.equal stdOptions

    # Don’t expect that the new controller was called
    # because we’re not testing the router. Just test
    # if execution stopped (e.g. Test1Controller is still active)
    d = dispatcher
    expect(d.previousRoute.controller).to.equal 'test1'
    expect(d.currentRoute.controller).to.equal 'test1'
    expect(d.currentController).to.be.an.instanceof Test1Controller
    expect(d.currentRoute.action).to.equal actionName
    expect(d.currentRoute.path).to.equal redirectToURLRoute.path

    dispatch.should.have.been.calledOnce
    route.should.have.been.calledOnce

    mediator.unsubscribe 'dispatcher:dispatch', dispatch
    action.restore()

  it 'should dispose when redirecting to a URL from controller action', ->
    class RedirectingController extends Controller
      show: ->
        dispatcher.controllerLoaded route1, null,
          {changeURL: true}, Test1Controller

    dispose = sinon.spy RedirectingController.prototype, 'dispose'

    name = 'redirecting_controller'
    makeLoadController name, RedirectingController

    route = {controller: name, action: 'show', path}
    publishMatch route, params, options
    dispose.should.have.been.calledOnce
    dispose.restore()

  it 'should dispose itself correctly', ->
    expect(dispatcher.dispose).to.be.a 'function'
    dispatcher.dispose()

    initialize = sinon.spy Test1Controller.prototype, 'initialize'
    publishMatch route1, params, options

    expect(dispatcher.disposed).to.be.true
    expect(dispatcher).to.be.frozen

    initialize.should.not.have.been.called
    initialize.restore()

  it 'should be extendable', ->
    expect(Dispatcher.extend).to.be.a 'function'

    DerivedDispatcher = Dispatcher.extend()
    derivedDispatcher = new DerivedDispatcher()
    expect(derivedDispatcher).to.be.an.instanceof Dispatcher

    derivedDispatcher.dispose()

  describe 'Before actions', ->

    class BeforeActionController extends Controller
      beforeAction: ->
      show: ->

    class NoBeforeController extends Controller
      beforeAction: null
      show: sinon.spy()

    makeLoadController 'before_action', BeforeActionController
    makeLoadController 'no_before_action', NoBeforeController

    it 'should run the before action', ->
      proto = BeforeActionController.prototype
      beforeAction = sinon.spy proto, 'beforeAction'
      action = sinon.spy proto, 'show'

      route = {controller: 'before_action', action: 'show', path}
      publishMatch route, params, options

      expect(beforeAction.calledBefore action).to.be.true
      expect(beforeAction.firstCall.thisValue)
        .to.be.an.instanceof BeforeActionController

      beforeAction.should.have.been.calledOnce
      beforeAction.restore()

      action.should.have.been.calledOnce
      action.restore()

    it 'should proceed if there is no before action', ->
      route = {controller: 'no_before_action', action: 'show', path}
      publishMatch route, params, options
      NoBeforeController::show.should.have.been.calledOnce

    it 'should throw an error if a before action method isn’t a function', ->
      class BrokenController extends Controller
        beforeAction: {}
        show: ->

      route = {controller: 'broken', action: 'show', path}
      failFunction = ->
        # Assume implementation detail (`controllerLoaded` method)
        # to bypass the asynchronous require(). An alternative would be
        # to mock require() so it’s synchronous.
        dispatcher.controllerLoaded route, params, options, BrokenController

      expect(failFunction).to.throw Error

    it 'should run the before action with the same arguments', ->
      action = sinon.spy()

      class BeforeActionChainController extends Controller
        beforeAction: (params, route, options) ->
          params.newParam = 'foo'
          options.newOption = 'bar'
        show: action

      name = 'before_action_chain'
      route = {controller: name, action: 'show', path}
      makeLoadController name, BeforeActionChainController

      publishMatch route, params, options
      action.should.have.been.calledOnce

      [passedParams, passedRoute, passedOptions] = action.firstCall.args

      params = Object.assign {}, params, newParam: 'foo'
      expect(passedParams).to.deep.equal params
      expect(passedRoute).to.deep.equal Object.assign {}, route

      options = Object.assign {}, stdOptions, newOption: 'bar'
      expect(passedOptions).to.deep.equal options

  describe 'Asynchronous Before Actions', ->

    it 'should handle asynchronous before actions', (done) ->
      resolve = null
      promise = new Promise (r) ->
        resolve = r

      class AsyncBeforeActionController extends Controller
        beforeAction: -> promise
        show: ->

      name = 'async_before_action'
      route = {controller: name, action: 'show', path}
      makeLoadController name, AsyncBeforeActionController

      action = sinon.spy AsyncBeforeActionController.prototype, 'show'

      publishMatch route, params, options
      action.should.not.have.been.called

      resolve()
      setImmediate ->
        action.should.have.been.calledOnce
        action.restore()

        done()

    it 'should support multiple asynchronous controllers', (done) ->

      class AsyncBeforeActionController extends Controller
        beforeAction: ->
          # Return an already resolved Promise
          { then : (callback) -> callback() }
        show: ->

      name = 'async_before_action2'
      route = {controller: name, action: 'show', path}
      makeLoadController name, AsyncBeforeActionController

      proto = AsyncBeforeActionController.prototype
      options.forceStartup = true

      i = 0

      test = ->
        beforeAction = sinon.spy proto, 'beforeAction'
        action = sinon.spy proto, 'show'
        publishMatch route, params, options

        beforeAction.should.have.been.calledOnce
        beforeAction.restore()

        action.should.have.been.calledOnce
        action.restore()

        if ++i < 4
          test()
        else
          done()

      test()

    it 'should kick around promises from compositions', (done) ->
      composer = new Composer()

      resolve = null
      promise = new Promise (r) ->
        resolve = r

      class AsyncBeforeActionController extends Controller
        beforeAction: -> @reuse 'a', -> promise
        show: ->

      name = 'async_before_action3'
      route = {controller: name, action: 'show', path}
      makeLoadController name, AsyncBeforeActionController

      proto = AsyncBeforeActionController.prototype
      options.forceStartup = true

      beforeAction = sinon.spy proto, 'beforeAction'
      action = sinon.spy proto, 'show'
      publishMatch route, params, options

      beforeAction.should.have.been.calledOnce
      action.should.not.have.been.called

      resolve()
      setImmediate ->
        beforeAction.restore()

        action.should.have.been.calledOnce
        action.restore()

        composer.dispose()
        done()

    it 'should stop dispatching when another controller is started', (done) ->
      resolve = null
      promise = new Promise (r) ->
        resolve = r

      class NeverendingController extends Controller
        beforeAction: -> promise
        show: ->

      name = 'neverending'
      firstRoute = {controller: name, action: 'show', path}
      makeLoadController name, NeverendingController

      # Spies
      proto = NeverendingController.prototype
      beforeAction = sinon.spy proto, 'beforeAction'
      firstAction = sinon.spy proto, 'show'
      secondAction = sinon.spy Test2Controller.prototype, 'show'

      # Start the neverending controller
      publishMatch firstRoute, params, options

      beforeAction.should.have.been.calledOnce
      firstAction.should.not.have.been.called

      # While the promise is pending, start another controller
      publishMatch route2, params, options
      secondAction.should.have.been.calledOnce

      # Test what happens when the Promise is resolved later
      resolve()
      setImmediate ->
        firstAction.should.have.been.calledOnce
        firstAction.restore()

        beforeAction.restore()
        secondAction.restore()

        done()
