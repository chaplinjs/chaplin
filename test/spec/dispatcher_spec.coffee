define [
  'underscore'
  'chaplin/mediator'
  'chaplin/controllers/controller'
  'chaplin/dispatcher'
], (_, mediator, Controller, Dispatcher) ->
  'use strict'
  describe 'Dispatcher', ->
    #console.debug 'Dispatcher spec'

    # Initialize shared variables
    dispatcher = params = routeOptions = null

    # Unique ID counter for creating params objects
    paramsId = 0

    # Fake route objects, walk like a route and swim like a route

    route1 = controller: 'test1', action: 'show'
    route2 = controller: 'test2', action: 'show'

    redirectToURLRoute = controller: 'test1', action: 'redirectToURL'
    redirectToControllerRoute = controller: 'test1', action: 'redirectToController'

    # Define test controllers
    class Test1Controller extends Controller

      historyURL: (params) ->
        #console.debug 'Test1Controller#historyURL'
        'test1/' + (params.id or '')

      initialize: (params, oldControllerName) ->
        #console.debug 'Test1Controller#initialize', params.id, oldControllerName
        super

      show: (params, oldControllerName) ->
        #console.debug 'Test1Controller#show', params, oldControllerName

      redirectToURL: (params, oldControllerName) ->
        @redirectTo '/test2/123'

      redirectToController: (params, oldControllerName) ->
        @redirectTo 'test2', 'show', params

      dispose: (params, newControllerName) ->
        #console.debug 'Test1Controller#dispose'
        super

    class Test2Controller extends Controller

      historyURL: (params) ->
        #console.debug 'Test2Controller#historyURL'
        'test2/' + (params.id or '')

      initialize: (params, oldControllerName) ->
        #console.debug 'Test2Controller#initialize', params, oldControllerName
        super

      show: (params, oldControllerName) ->
        #console.debug 'Test2Controller#show', params, oldControllerName

      dispose: (params, newControllerName) ->
        #console.debug 'Test2Controller#dispose'
        super

    # Define a test controller AMD modules
    test1Module = 'controllers/test1_controller'
    test2Module = 'controllers/test2_controller'
    define test1Module, -> Test1Controller
    define test2Module, -> Test2Controller

    # Helpers for asynchronous tests
    test1Loaded = (callback) -> require [test1Module], callback
    test2Loaded = (callback) -> require [test2Module], callback

    # Reset helpers

    refreshParams = ->
      # Create a fresh params object which does not equal the previous one
      params = id: paramsId++
      routeOptions = changeURL: false

    beforeEach refreshParams

    it 'should initialize', ->
      dispatcher = new Dispatcher()

    it 'should dispatch routes to controller actions', (done) ->
      proto = Test1Controller.prototype
      initialize = sinon.spy proto, 'initialize'
      action     = sinon.spy proto, 'show'
      historyURL = sinon.spy proto, 'historyURL'

      mediator.publish 'matchRoute', route1, params, routeOptions

      test1Loaded ->
        expect(initialize).was.calledWith params, null
        expect(action).was.calledWith params, null
        expect(historyURL).was.calledWith params

        initialize.restore()
        action.restore()
        historyURL.restore()

        done()

    it 'should not start the same controller if params match', (done)->
      mediator.publish 'matchRoute', route1, params, routeOptions

      test1Loaded ->
        proto = Test1Controller.prototype
        initialize = sinon.spy proto, 'initialize'
        action     = sinon.spy proto, 'show'
        historyURL = sinon.spy proto, 'historyURL'

        mediator.publish 'matchRoute', route1, params, routeOptions

        test1Loaded ->
          expect(initialize).was.notCalled()
          expect(action).was.notCalled()
          expect(historyURL).was.notCalled()

          initialize.restore()
          action.restore()
          historyURL.restore()

          done()

    it 'should start the same controller if params differ', (done) ->
      mediator.publish 'matchRoute', route1, params, routeOptions

      proto = Test1Controller.prototype
      initialize = sinon.spy proto, 'initialize'
      action     = sinon.spy proto, 'show'
      historyURL = sinon.spy proto, 'historyURL'

      refreshParams()
      mediator.publish 'matchRoute', route1, params, routeOptions

      test1Loaded ->
        expect(initialize).was.calledWith params, 'test1'
        expect(action).was.calledWith params, 'test1'
        expect(historyURL).was.calledWith params

        initialize.restore()
        action.restore()
        historyURL.restore()

        done()

    it 'should start the same controller if forced', (done) ->
      mediator.publish 'matchRoute', route1, params, routeOptions

      proto = Test1Controller.prototype
      initialize = sinon.spy proto, 'initialize'
      action     = sinon.spy proto, 'show'
      historyURL = sinon.spy proto, 'historyURL'

      routeOptions.forceStartup = true
      mediator.publish 'matchRoute', route1, params, routeOptions

      test1Loaded ->
        expect(initialize).was.calledWith params, 'test1'
        expect(action).was.calledWith params, 'test1'
        expect(historyURL).was.calledWith params

        initialize.restore()
        action.restore()
        historyURL.restore()

        done()

    it 'should save the controller, action, params and url', (done) ->
      # Now route to Test2Controller
      mediator.publish 'matchRoute', route2, params, routeOptions

      test2Loaded ->
        d = dispatcher
        expect(d.previousControllerName).to.be 'test1'
        expect(d.currentControllerName).to.be 'test2'
        expect(d.currentController).to.be.a Test2Controller
        expect(d.currentAction).to.be 'show'
        expect(d.currentParams).to.be params
        expect(d.url).to.be "test2/#{params.id}"

        done()

    it 'should dispose inactive controllers and fire beforeControllerDispose events', (done) ->
      dispose = sinon.spy Test2Controller.prototype, 'dispose'

      # Route back to Test1Controller
      mediator.publish 'matchRoute', route1, params, routeOptions

      test2Loaded ->
        expect(dispose).was.calledWith params, 'test1'

        dispose.restore()

        done()

    it 'should fire beforeControllerDispose events', (done) ->
      beforeControllerDispose = sinon.spy()
      mediator.subscribe 'beforeControllerDispose', beforeControllerDispose

      # Now route to Test2Controller
      mediator.publish 'matchRoute', route2, params, routeOptions

      test2Loaded ->
        expect(beforeControllerDispose).was.called()
        passedController = beforeControllerDispose.lastCall.args[0]
        expect(passedController).to.be.a Test1Controller
        expect(passedController.disposed).to.be true

        mediator.unsubscribe 'beforeControllerDispose', beforeControllerDispose

        done()

    it 'should publish startupController events', (done) ->
      startupController = sinon.spy()
      mediator.subscribe 'startupController', startupController

      # Route back to Test1Controller
      mediator.publish 'matchRoute', route1, params, routeOptions

      test1Loaded ->
        passedEvent = startupController.lastCall.args[0]
        expect(passedEvent).to.be.an 'object'
        expect(passedEvent.controller).to.be.a Test1Controller
        expect(passedEvent.controllerName).to.be 'test1'
        expect(passedEvent.params).to.be params
        expect(passedEvent.previousControllerName).to.be 'test2'

        mediator.unsubscribe 'startupController', startupController

        done()

    it 'should listen to !startupController events', (done) ->
      proto = Test1Controller.prototype
      initialize = sinon.spy proto, 'initialize'
      action     = sinon.spy proto, 'show'
      historyURL = sinon.spy proto, 'historyURL'

      mediator.publish '!startupController', 'test1', 'show', params,
        routeOptions

      test1Loaded ->
        expect(initialize).was.calledWith params, 'test1'
        expect(action).was.calledWith params, 'test1'
        expect(historyURL).was.calledWith params

        d = dispatcher
        expect(d.previousControllerName).to.be 'test1'
        expect(d.currentControllerName).to.be 'test1'
        expect(d.currentController).to.be.a Test1Controller
        expect(d.currentAction).to.be 'show'
        expect(d.currentParams).to.be params
        expect(d.url).to.be "test1/#{params.id}"

        initialize.restore()
        action.restore()
        historyURL.restore()

        done()

    it 'should adjust the URL and pass route options', (done) ->
      spy = sinon.spy()
      mediator.subscribe '!router:changeURL', spy

      routeOptions = replace: true
      mediator.publish '!startupController', 'test1', 'show', params,
        routeOptions

      test1Loaded ->
        expect(spy).was.calledWith "test1/#{params.id}", routeOptions

        mediator.unsubscribe '!router:changeURL', spy

        done()

    it 'should use the path from the route options', (done) ->
      spy = sinon.spy()
      mediator.subscribe '!router:changeURL', spy

      routeOptions = path: 'custom-path-from-options'
      mediator.publish '!startupController', 'test1', 'show', params,
        routeOptions

      test1Loaded ->
        expect(spy).was.calledWith routeOptions.path, routeOptions

        mediator.unsubscribe '!router:changeURL', spy

        done()

    it 'should support redirection to a URL', (done) ->
      proto = Test1Controller.prototype
      action = sinon.spy proto, 'redirectToURL'

      startupController = sinon.spy()
      mediator.subscribe 'startupController', startupController

      mediator.publish 'matchRoute', redirectToURLRoute, params, routeOptions

      test1Loaded ->
        expect(action).was.calledWith params, 'test1'

        # Don’t expect that the new controller was called
        # because we’re not testing the router. Just test
        # if execution stopped (e.g. Test1Controller is still active)
        d = dispatcher
        expect(d.previousControllerName).to.be 'test1'
        expect(d.currentControllerName).to.be 'test1'
        expect(d.currentController).to.be.a Test1Controller
        expect(d.currentAction).to.be 'show'
        expect(d.currentParams).not.to.be params
        expect(d.url).not.to.be "test1/#{params.id}"

        expect(startupController).was.notCalled()

        mediator.unsubscribe 'startupController', startupController
        action.restore()

        done()

    it 'should support redirection to a controller action', (done) ->
      proto = Test1Controller.prototype
      redirectAction = sinon.spy proto, 'redirectToController'

      proto = Test2Controller.prototype
      targetAction = sinon.spy proto, 'show'

      startupController = sinon.spy()
      mediator.subscribe 'startupController', startupController

      # Redirects from Test1Controller to Test2Controller
      mediator.publish 'matchRoute', redirectToControllerRoute, params,
        routeOptions

      # Double async module loading to trick Require.js
      test1Loaded -> test2Loaded ->
        expect(redirectAction).was.calledWith params, 'test1'
        expect(targetAction).was.calledWith params, 'test1'

        # Expect that the new controller was called because this does not require
        # the router but the controller to fire a !startupController event
        d = dispatcher
        expect(d.previousControllerName).to.be 'test1'
        expect(d.currentControllerName).to.be 'test2'
        expect(d.currentController).to.be.a Test2Controller
        expect(d.currentAction).to.be 'show'
        expect(d.currentParams).to.be params
        expect(d.url).to.be "test2/#{params.id}"

        # startupController event was only triggered once
        expect(startupController).was.called()
        expect(startupController.callCount).to.be 1

        mediator.unsubscribe 'startupController', startupController
        redirectAction.restore()

        done()

    it 'should dispose itself correctly', (done) ->
      expect(dispatcher.dispose).to.be.a 'function'
      dispatcher.dispose()

      proto = Test1Controller.prototype
      initialize = sinon.spy proto, 'initialize'
      mediator.publish 'matchRoute', route1, params, routeOptions

      test1Loaded ->
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

    describe 'Before filters', ->

      describe "General behavior", ->

        route = controller: 'test_filters', action: 'show'

        class TestFiltersController extends Controller

          historyURL: (params) ->
            'test_filters/' + (params.id or '')

          before:
            show: ->
            index: ->

          show: (params, oldControllerName) ->

          index: (params, oldControllerName) ->


        # Define a test controller AMD modules
        testFiltersModule = 'controllers/test_filters_controller'
        define testFiltersModule, -> TestFiltersController

        # Helpers for asynchronous tests
        testFiltersLoaded = (callback) -> require [testFiltersModule], callback

        beforeEach ->
          dispatcher = new Dispatcher()

        afterEach ->
          dispatcher.dispose()

        it 'should not run executeAction directly if filters are present', (done) ->
          executeAction = sinon.spy dispatcher, 'executeAction'
          executeFilters = sinon.mock(dispatcher).expects 'executeFilters'

          mediator.publish 'matchRoute', route, params, routeOptions

          testFiltersLoaded ->
            expect(executeAction.called).to.not.be.ok()
            expect(executeFilters.getCall(0).args[0]).to.be.a TestFiltersController

            executeAction.restore()
            executeFilters.verify()

            done()

        it 'should trigger before filter', (done) ->
          proto = TestFiltersController.prototype
          beforeFiltersSpy = sinon.spy proto, 'configureBeforeFilters'
          mediator.publish 'matchRoute', route, params, routeOptions

          testFiltersLoaded ->
            expect(beforeFiltersSpy).was.called()
            beforeFiltersSpy.restore()
            done()


      describe '#executeFilters', ->

        it "should list and run all filters", ->
          called = []

          class TestController extends Controller

            historyURL: (params) ->
              'test1/' + (params.id or '')

            before:
              show: ->
                console.log 'showFilter'
                called.unshift 'showFilter'
              'show*': ->
                console.log 'showWildcardFilter'
                called.unshift 'showWildcardFilter'
              create: ->
                console.log 'createFilter'
                called.unshift 'createFilter'

            show: ->
              expect(called).to.have.length 2
              expect(called).to.contain 'showFilter'
              expect(called).to.contain 'showWildcardFilter'

            create: ->
              expect(called).to.have.length 1
              expect(called).to.contain 'createFilter'

          dispatcher = new Dispatcher()
          controller = new TestController()

          dispatcher.executeFilters controller, 'test', 'show', params, routeOptions

          called = []

          dispatcher.executeFilters controller, 'test', 'create', params, routeOptions


        it 'should throw an error if a filter method isn\'t a function or a string', ->

          class BrokenFilterController extends Controller
            historyURL: (params) -> 'foo'
            before:
              index: new Date()
            index: ->

          controller = new BrokenFilterController()

          failFn = -> dispatcher.executeFilters controller, 'broken_filter', 'index', params, routeOptions
          expect(failFn).to.throwError()


        it 'should call executeAction with exactly the same arguments', ->
        it 'should handle sync. filters then pass the returned value', ->
        it 'should handle async. filters, then pass the returned value', ->


