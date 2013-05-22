define [
  'underscore'
  'jquery'
  'chaplin/mediator'
  'chaplin/controllers/controller'
  'chaplin/dispatcher'
], (_, $, mediator, Controller, Dispatcher) ->
  'use strict'

  describe 'Dispatcher', ->
    # Initialize shared variables
    dispatcher = params = path = options = stdOptions = route1 = route2 =
      redirectToURLRoute = redirectToControllerRoute = null

    # Default options which are added on first dispatching

    addedOptions =
      changeURL: true
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

    # Define an AMD module and return a loader function
    makeLoadController = (moduleName, module) ->
      moduleName = "controllers/#{moduleName}_controller"
      define moduleName, -> module
      (callback) ->
        require [moduleName], callback

    # Define a test controller AMD modules
    loadTest1Controller = makeLoadController 'test1', Test1Controller
    loadTest2Controller = makeLoadController 'test2', Test2Controller

    # Shortcut for publishing router:match events
    publishMatch = ->
      mediator.publish 'router:match', arguments...

    # Helper for creating params/options to compare with
    create = ->
      _.extend {}, arguments...

    # Reset helper: Create fresh params and options
    refreshParams = ->
      params = id: _.uniqueId('paramsId')
      path = "test/#{params.id}"
      options = {}
      stdOptions = create addedOptions

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

    # The Tests

    it 'should dispatch routes to controller actions', (done) ->
      proto = Test1Controller.prototype
      initialize = sinon.spy proto, 'initialize'
      action     = sinon.spy proto, 'show'

      publishMatch route1, params, options

      loadTest1Controller ->
        for spy in [initialize, action]
          expect(spy).was.calledOnce()
          expect(spy.firstCall.thisValue).to.be.a Test1Controller
          [passedParams, passedRoute, passedOptions] = spy.firstCall.args
          expect(passedParams).to.eql params
          expect(passedRoute).to.eql create(route1, previous: {})
          expect(passedOptions).to.eql stdOptions

        initialize.restore()
        action.restore()

        done()

    it 'should not start the same controller if params match', (done) ->
      publishMatch route1, params, options

      loadTest1Controller ->
        proto = Test1Controller.prototype
        initialize = sinon.spy proto, 'initialize'
        action     = sinon.spy proto, 'show'

        publishMatch route1, params, options

        loadTest1Controller ->
          expect(initialize).was.notCalled()
          expect(action).was.notCalled()

          initialize.restore()
          action.restore()

          done()

    it 'should start the same controller if params differ', (done) ->
      proto = Test1Controller.prototype
      initialize = sinon.spy proto, 'initialize'
      action     = sinon.spy proto, 'show'

      paramsStore = []
      optionsStore = []

      for i in [0..1]
        refreshParams()
        paramsStore.push params
        optionsStore.push options
        publishMatch route1, params, options

      loadTest1Controller ->
        expect(initialize).was.calledTwice()
        expect(action).was.calledTwice()

        for i in [0..1]
          for spy in [initialize, action]
            [passedParams, passedRoute, passedOptions] = spy.args[i]
            expect(passedParams).to.eql paramsStore[i]
            expect(passedRoute.controller).to.eql route1.controller
            expect(passedRoute.action).to.eql route1.action
            if i is 1
              expect(passedRoute.previous.controller).to.eql route1.controller
            expect(passedOptions).to.eql stdOptions

        initialize.restore()
        action.restore()

        done()

    it 'should start the same controller if forced', (done) ->
      proto = Test1Controller.prototype
      initialize = sinon.spy proto, 'initialize'
      action     = sinon.spy proto, 'show'

      paramsStore = []
      optionsStore = []

      for i in [0..1]
        refreshParams()
        paramsStore.push params
        optionsStore.push options
        options.forceStartup = true if i is 1
        publishMatch route1, params, options

      loadTest1Controller ->
        for i in [0..1]
          for spy in [initialize, action]
            [passedParams, passedRoute, passedOptions] = spy.args[i]
            expect(passedParams).to.eql paramsStore[i]
            expect(passedRoute.controller).to.be route1.controller
            expect(passedRoute.action).to.be route1.action
            expectedOptions = create optionsStore[i], {
              changeURL: true
              forceStartup: (if i is 0 then false else true)
            }
            expect(passedOptions).to.eql expectedOptions

        initialize.restore()
        action.restore()

        done()

    it 'should save the controller, action, params and path', (done) ->
      publishMatch route1, params, options
      publishMatch route2, params, options

      # Check that previous route is saved
      loadTest1Controller -> loadTest2Controller ->
        d = dispatcher
        expect(d.previousRoute.controller).to.be 'test1'
        expect(d.currentController).to.be.a Test2Controller
        expect(d.currentRoute).to.eql create(route2, previous: {})
        expect(d.currentParams).to.eql params

        done()

    it 'should add the previous controller name to the route', (done) ->
      action = sinon.spy Test2Controller.prototype, 'show'

      publishMatch route1, params, options

      loadTest1Controller ->
        publishMatch route2, params, options

        loadTest2Controller ->
          expect(action).was.calledOnce()
          route = action.firstCall.args[1]
          expect(route.controller).to.be route2.controller
          expect(route.action).to.be route2.action
          expect(route.previous).to.be.an 'object'
          expect(route.previous.controller).to.be route1.controller
          expect(route.previous.action).to.be route1.action

          action.restore()

          done()

    it 'should dispose inactive controllers', (done) ->
      dispose = sinon.spy Test1Controller.prototype, 'dispose'
      publishMatch route1, params, options
      publishMatch route2, params, options

      loadTest1Controller -> loadTest2Controller ->
        # It should pass the params and the new controller name
        expect(dispose).was.calledOnce()
        [passedParams, passedRoute] = dispose.firstCall.args
        expect(passedParams).to.eql params
        expect(passedRoute.controller).to.eql route2.controller
        expect(passedRoute.action).to.eql route2.action
        expect(passedRoute.path).to.eql route2.path

        dispose.restore()

        done()

    it 'should fire beforeControllerDispose events', (done) ->
      publishMatch route1, params, options

      beforeControllerDispose = sinon.spy()
      mediator.subscribe 'beforeControllerDispose', beforeControllerDispose

      # Now route to Test2Controller
      publishMatch route2, params, options

      loadTest1Controller -> loadTest2Controller ->
        expect(beforeControllerDispose).was.calledOnce()

        # Event payload should be the now disposed controller
        passedController = beforeControllerDispose.firstCall.args[0]
        expect(passedController).to.be.a Test1Controller
        expect(passedController.disposed).to.be true

        mediator.unsubscribe 'beforeControllerDispose', beforeControllerDispose

        done()

    it 'should publish dispatch events', (done) ->
      dispatch = sinon.spy()
      mediator.subscribe 'dispatcher:dispatch', dispatch

      publishMatch route1, params, options
      publishMatch route2, params, options

      loadTest1Controller -> loadTest2Controller ->
        expect(dispatch).was.calledTwice()

        for i in [0..1]
          firstCall = i is 0
          args = dispatch.getCall(i).args
          expect(args.length).to.be 4
          [passedController, passedParams, passedRoute, passedOptions] = args
          expect(passedController).to.be.a(
            if firstCall then Test1Controller else Test2Controller
          )
          expect(passedParams).to.eql params
          expect(passedRoute.controller).to.be(
            if firstCall then 'test1' else 'test2'
          )
          expect(passedRoute.action).to.be 'show'
          expect(passedRoute.previous.controller).to.be(
            if firstCall then undefined else 'test1'
          )
          expect(passedOptions).to.eql stdOptions

        mediator.unsubscribe 'dispatcher:dispatch', dispatch

        done()

    it 'should adjust the URL and pass route options', (done) ->
      spy = sinon.spy()
      mediator.subscribe '!router:changeURL', spy

      path = 'my-little-path'
      routeA = create route1, {path}
      options = {}
      publishMatch routeA, params, options

      loadTest1Controller ->
        expect(spy).was.calledOnce()
        [passedPath, passedOptions] = spy.firstCall.args
        expect(passedPath).to.be path
        expect(passedOptions).to.eql stdOptions

        mediator.unsubscribe '!router:changeURL', spy

        done()

    it 'should not adjust the URL if not desired', (done) ->
      spy = sinon.spy()
      mediator.subscribe '!router:changeURL', spy

      publishMatch route1, params, changeURL: false

      loadTest1Controller ->
        expect(spy).was.notCalled()

        mediator.unsubscribe '!router:changeURL', spy

        done()

    it 'should add the query string when adjusting the URL', (done) ->
      spy = sinon.spy()
      mediator.subscribe '!router:changeURL', spy

      path = 'my-little-path'
      query = 'foo=bar'

      routeB = create route1, {path, query}
      publishMatch routeB, params, options

      loadTest1Controller ->
        expect(spy).was.calledOnce()
        [passedPath, passedOptions]  = spy.firstCall.args
        expect(passedPath).to.be "#{path}?#{query}"
        expect(passedOptions).to.eql stdOptions

        mediator.unsubscribe '!router:changeURL', spy

        done()

    it 'should support redirection to a URL', (done) ->
      dispatch = sinon.spy()
      mediator.subscribe 'dispatcher:dispatch', dispatch

      # Dispatch a route to check if previous controller info is correct after
      # redirection
      publishMatch route1, params, options

      # Open another route that redirects somewhere
      refreshParams()
      actionName = 'redirectToURL'
      action = sinon.spy Test1Controller.prototype, actionName
      publishMatch redirectToURLRoute, params, options

      loadTest1Controller ->
        expect(action).was.calledOnce()
        [passedParams, passedRoute, passedOptions] = action.firstCall.args
        expect(passedParams).to.eql params
        expect(passedRoute.previous.controller).to.eql 'test1'
        expect(passedOptions).to.eql stdOptions

        # Don’t expect that the new controller was called
        # because we’re not testing the router. Just test
        # if execution stopped (e.g. Test1Controller is still active)
        d = dispatcher
        expect(d.previousRoute.controller).to.be 'test1'
        expect(d.currentRoute.controller).to.be 'test1'
        expect(d.currentController).to.be.a Test1Controller
        expect(d.currentRoute.action).to.be actionName
        expect(d.currentRoute.path).to.be redirectToURLRoute.path

        expect(dispatch).was.calledOnce()

        mediator.unsubscribe 'dispatcher:dispatch', dispatch
        action.restore()

        done()

    it 'should dispose when redirecting to a URL', (done) ->
      dispose = sinon.spy Test1Controller.prototype, 'dispose'
      publishMatch route1, params, options
      publishMatch redirectToURLRoute, params, options
      loadTest1Controller ->
        expect(dispose).was.calledOnce()
        dispose.restore()
        done()

    it 'should dispose itself correctly', (done) ->
      expect(dispatcher.dispose).to.be.a 'function'
      dispatcher.dispose()

      initialize = sinon.spy Test1Controller.prototype, 'initialize'
      publishMatch route1, params, options

      loadTest1Controller ->
        expect(initialize).was.notCalled()

        expect(dispatcher.disposed).to.be true
        if Object.isFrozen
          expect(Object.isFrozen(dispatcher)).to.be true

        initialize.restore()

        done()

    it 'should be extendable', ->
      expect(Dispatcher.extend).to.be.a 'function'

      DerivedDispatcher = Dispatcher.extend()
      derivedDispatcher = new DerivedDispatcher()
      expect(derivedDispatcher).to.be.a Dispatcher

      derivedDispatcher.dispose()

    describe 'Before actions', ->

      class NoBeforeController extends Controller
        beforeAction: null
        show: sinon.spy()

      class BeforeActionController extends Controller
        beforeAction: ->
        show: ->

      loadController = makeLoadController 'before_action',
        BeforeActionController

      beforeActionRoute = {controller: 'before_action', action: 'show', path}

      it 'should run the before action', (done) ->
        proto = BeforeActionController.prototype
        beforeAction = sinon.spy proto, 'beforeAction'
        action = sinon.spy proto, 'show'
        publishMatch beforeActionRoute, params, options

        loadController ->
          expect(beforeAction).was.calledOnce()
          expect(beforeAction.firstCall.thisValue).to.be.a BeforeActionController
          expect(action).was.calledOnce()
          expect(beforeAction.calledBefore(action)).to.be true

          beforeAction.restore()
          action.restore()

          done()

      it 'should proceed if there is no before action', (done) ->
        controllerName = 'no_before_action'
        loadController = makeLoadController controllerName, NoBeforeController
        route = {controller: controllerName, action: 'show', path}
        publishMatch route, params, options
        loadController ->
          expect(NoBeforeController::show).was.calledOnce()
          done()

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

        expect(failFunction).to.throwError()

      it 'should run the before action with the same arguments', (done) ->
        action = sinon.spy()

        class BeforeActionChainController extends Controller
          beforeAction: (params, route, options) ->
            params.newParam = 'foo'
            options.newOption = 'bar'
          show: action

        controllerName = 'before_action_chain'
        loadController = makeLoadController controllerName,
          BeforeActionChainController

        route = {controller: controllerName, action: 'show', path}
        publishMatch route, params, options

        loadController ->
          expect(action).was.calledOnce()
          [passedParams, passedRoute, passedOptions] = action.firstCall.args
          expect(passedParams).to.eql create(params, newParam: 'foo')
          expect(passedRoute).to.eql create(route, previous: {})
          expect(passedOptions).to.eql create(stdOptions, newOption: 'bar')

          done()

    describe 'Asynchronous Before Actions', ->

      it 'should handle asynchronous before actions', (done) ->
        deferred = $.Deferred()
        promise = deferred.promise()

        class AsyncBeforeActionController extends Controller
          beforeAction: -> promise
          show: ->

        controllerName = 'async_before_action'
        loadController = makeLoadController controllerName,
          AsyncBeforeActionController

        action = sinon.spy AsyncBeforeActionController.prototype, 'show'

        route = {controller: controllerName, action: 'show', path}
        publishMatch route, params, options

        loadController ->
          expect(action).was.notCalled()
          deferred.resolve()
          expect(action).was.calledOnce()

          action.restore()

          done()

      it 'should support multiple asynchronous controllers', (done) ->

        class AsyncBeforeActionController extends Controller
          beforeAction: ->
            # Return an already resolved Promise
            { then : (callback) -> callback() }
          show: ->

        controllerName = 'async_before_action2'
        loadController = makeLoadController controllerName,
          AsyncBeforeActionController

        route = {controller: controllerName, action: 'show', path}
        options.forceStartup = true

        proto = AsyncBeforeActionController.prototype
        i = 0
        times = 4

        test = ->
          beforeAction = sinon.spy proto, 'beforeAction'
          action = sinon.spy proto, 'show'
          publishMatch route, params, options

          loadController ->
            expect(beforeAction).was.calledOnce()
            expect(action).was.calledOnce()

            beforeAction.restore()
            action.restore()

            i++
            if i < times
              test()
            else
              done()

        test()

      it 'should stop dispatching when another controller is started', (done) ->
        deferred = $.Deferred()
        promise = deferred.promise()

        class NeverendingController extends Controller
          beforeAction: -> promise
          show: ->

        controllerName = 'neverending'
        loadNeverendingController = makeLoadController controllerName,
          NeverendingController

        firstRoute = {controller: controllerName, action: 'show', path}
        secondRoute = route2

        # Spies
        proto = NeverendingController.prototype
        beforeAction = sinon.spy proto, 'beforeAction'
        firstAction = sinon.spy proto, 'show'
        secondAction = sinon.spy Test2Controller.prototype, 'show'

        # Start the neverending controller
        publishMatch firstRoute, params, options

        loadNeverendingController ->
          expect(beforeAction).was.calledOnce()
          expect(firstAction).was.notCalled()

          # While the promise is pending, start another controller
          publishMatch secondRoute, params, options

          loadTest2Controller ->
            expect(secondAction).was.calledOnce()

            # Test what happens when the Promise is resolved later
            deferred.resolve()
            expect(firstAction).was.notCalled()

            beforeAction.restore()
            firstAction.restore()
            secondAction.restore()

            done()
