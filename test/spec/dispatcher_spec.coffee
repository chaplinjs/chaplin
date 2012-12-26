define [
  'underscore'
  'jquery'
  'backbone'
  'chaplin/mediator'
  'chaplin/controllers/controller'
  'chaplin/dispatcher'
], (_, $, Backbone, mediator, Controller, Dispatcher) ->
  'use strict'
  describe 'Dispatcher', ->
    #console.debug 'Dispatcher spec'

    # Initialize shared variables
    dispatcher = params = routeOptions = null

    # Fake route objects, walk like a route and swim like a route

    route1 = controller: 'test1', action: 'show'
    route2 = controller: 'test2', action: 'show'

    redirectToURLRoute = controller: 'test1', action: 'redirectToURL'
    redirectToControllerRoute = controller: 'test1', action: 'redirectToController'

    # Define test controllers

    Test1Controller = class Test1Controller extends Controller
      initialize: (params, oldControllerName) ->
        #console.debug 'Test1Controller#initialize', params.id, oldControllerName
        super

      show: (params, oldControllerName) ->
        #console.debug 'Test1Controller#show', params, oldControllerName

      redirectToURL: (params, oldControllerName) ->
        @redirectTo '/test/123'

      dispose: (params, newControllerName) ->
        #console.debug 'Test1Controller#dispose'
        super

    Test2Controller = class Test2Controller extends Controller
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
    loadTest1ControllerAndExecute = (callback) -> require [test1Module], callback
    loadTest2ControllerAndExecute = (callback) -> require [test2Module], callback

    # Create a fresh Dispatcher instance for each test

    beforeEach ->
      dispatcher = new Dispatcher()

    afterEach ->
      dispatcher.dispose()
      dispatcher = null

    # Reset helpers

    # Unique ID counter for creating params objects
    paramsId = 0

    refreshParams = ->
      # Create a fresh params object which does not equal the previous one
      params = id: paramsId++
      routeOptions = changeURL: false, path: "test/#{params.id}"

    beforeEach refreshParams


    it 'should dispatch routes to controller actions', (done) ->
      proto = Test1Controller.prototype
      initialize = sinon.spy proto, 'initialize'
      action     = sinon.spy proto, 'show'

      Backbone.trigger 'matchRoute', route1, params, routeOptions

      loadTest1ControllerAndExecute ->
        expect(initialize).was.calledWith params, null
        expect(action).was.calledWith params, null

        initialize.restore()
        action.restore()

        done()

    it 'should not start the same controller if params match', (done)->
      Backbone.trigger 'matchRoute', route1, params, routeOptions

      loadTest1ControllerAndExecute ->
        proto = Test1Controller.prototype
        initialize = sinon.spy proto, 'initialize'
        action     = sinon.spy proto, 'show'

        Backbone.trigger 'matchRoute', route1, params, routeOptions

        loadTest1ControllerAndExecute ->
          expect(initialize).was.notCalled()
          expect(action).was.notCalled()

          initialize.restore()
          action.restore()

          done()

    it 'should start the same controller if params differ', (done) ->
      Backbone.trigger 'matchRoute', route1, params, routeOptions

      proto = Test1Controller.prototype
      initialize = sinon.spy proto, 'initialize'
      action     = sinon.spy proto, 'show'

      refreshParams()
      Backbone.trigger 'matchRoute', route1, params, routeOptions

      loadTest1ControllerAndExecute ->
        expect(initialize).was.calledWith params, 'test1'
        expect(action).was.calledWith params, 'test1'

        initialize.restore()
        action.restore()

        done()

    it 'should start the same controller if forced', (done) ->
      Backbone.trigger 'matchRoute', route1, params, routeOptions

      proto = Test1Controller.prototype
      initialize = sinon.spy proto, 'initialize'
      action     = sinon.spy proto, 'show'

      routeOptions.forceStartup = true
      Backbone.trigger 'matchRoute', route1, params, routeOptions

      loadTest1ControllerAndExecute ->
        expect(initialize).was.calledWith params, 'test1'
        expect(action).was.calledWith params, 'test1'

        initialize.restore()
        action.restore()

        done()

    it 'should save the controller, action, params and url', (done) ->

      # Call one route
      Backbone.trigger 'matchRoute', route1, params, routeOptions

      # Now open another route
      Backbone.trigger 'matchRoute', route2, params, routeOptions

      # Check that previous route is saved
      loadTest2ControllerAndExecute ->
        d = dispatcher
        expect(d.previousControllerName).to.be 'test1'
        expect(d.currentControllerName).to.be 'test2'
        expect(d.currentController).to.be.a Test2Controller
        expect(d.currentAction).to.be 'show'
        expect(d.currentParams).to.be params
        expect(d.url).to.be "test/#{params.id}"

        done()

    it 'should dispose inactive controllers and fire beforeControllerDispose events', (done) ->
      Backbone.trigger 'matchRoute', route2, params, routeOptions

      dispose = sinon.spy Test2Controller.prototype, 'dispose'

      # Route back to Test1Controller
      Backbone.trigger 'matchRoute', route1, params, routeOptions

      loadTest2ControllerAndExecute ->
        expect(dispose).was.calledWith params, 'test1'

        dispose.restore()

        done()

    it 'should fire beforeControllerDispose events', (done) ->
      Backbone.trigger 'matchRoute', route1, params, routeOptions

      beforeControllerDispose = sinon.spy()
      Backbone.on 'beforeControllerDispose', beforeControllerDispose

      # Now route to Test2Controller
      Backbone.trigger 'matchRoute', route2, params, routeOptions

      loadTest2ControllerAndExecute ->
        expect(beforeControllerDispose).was.called()
        passedController = beforeControllerDispose.lastCall.args[0]
        expect(passedController).to.be.a Test1Controller
        expect(passedController.disposed).to.be true

        Backbone.off 'beforeControllerDispose', beforeControllerDispose

        done()

    it 'should publish startupController events', (done) ->
      Backbone.trigger 'matchRoute', route2, params, routeOptions

      startupController = sinon.spy()
      Backbone.on 'startupController', startupController

      # Route back to Test1Controller
      Backbone.trigger 'matchRoute', route1, params, routeOptions

      loadTest1ControllerAndExecute ->
        passedEvent = startupController.lastCall.args[0]
        expect(passedEvent).to.be.an 'object'
        expect(passedEvent.controller).to.be.a Test1Controller
        expect(passedEvent.controllerName).to.be 'test1'
        expect(passedEvent.params).to.be params
        expect(passedEvent.previousControllerName).to.be 'test2'

        Backbone.off 'startupController', startupController

        done()

    it 'should adjust the URL and pass route options', (done) ->
      spy = sinon.spy()
      Backbone.on '!router:changeURL', spy

      routeOptions = replace: true, path: 'some-path'
      dispatcher.startupController 'test1', 'show', params, routeOptions

      loadTest1ControllerAndExecute ->
        expect(spy).was.calledWith routeOptions.path, routeOptions

        Backbone.off '!router:changeURL', spy

        done()

    it 'should use the path from the route options', (done) ->
      spy = sinon.spy()
      Backbone.on '!router:changeURL', spy

      routeOptions = path: 'custom-path-from-options'
      dispatcher.startupController 'test1', 'show', params, routeOptions

      loadTest1ControllerAndExecute ->
        expect(spy).was.calledWith routeOptions.path, routeOptions

        Backbone.off '!router:changeURL', spy

        done()

    it 'should support redirection to a URL', (done) ->

      # Open a route to check if previous controller info is correct after
      # redirection

      Backbone.trigger 'matchRoute', route1, params, routeOptions
      refreshParams()

      action = sinon.spy Test1Controller.prototype, 'redirectToURL'

      startupController = sinon.spy()
      Backbone.on 'startupController', startupController

      # Open another route that redirects somewhere

      Backbone.trigger 'matchRoute', redirectToURLRoute, params, routeOptions

      loadTest1ControllerAndExecute ->
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
        expect(d.url).not.to.be "test/#{params.id}"

        expect(startupController).was.calledOnce()

        Backbone.off 'startupController', startupController
        action.restore()

        done()

    it 'should dispose itself correctly', (done) ->
      expect(dispatcher.dispose).to.be.a 'function'
      dispatcher.dispose()

      initialize = sinon.spy Test1Controller.prototype, 'initialize'
      Backbone.trigger 'matchRoute', route1, params, routeOptions

      loadTest1ControllerAndExecute ->
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

      route = controller: 'test_before_actions', action: 'show'

      class TestBeforeActionsController extends Controller
        beforeAction:
          show: ->
          index: ->

        show: (params, oldControllerName) ->

        index: (params, oldControllerName) ->

      # Define a test controller AMD module
      testBeforeActionsModule = 'controllers/test_before_actions_controller'
      define testBeforeActionsModule, -> TestBeforeActionsController

      # Helpers for asynchronous tests
      loadBeforeActionsAndExecute = (callback) ->
        require [testBeforeActionsModule], callback

      it 'should not run executeAction directly if before actions are present', (done) ->
        executeAction = sinon.spy dispatcher, 'executeAction'
        # Replace executeBeforeActionChain with a no-op stub
        executeBeforeActionChain = sinon.stub dispatcher, 'executeBeforeActionChain'

        Backbone.trigger 'matchRoute', route, params, routeOptions

        loadBeforeActionsAndExecute ->
          expect(executeAction).was.notCalled()
          expect(executeBeforeActionChain).was.called()
          expect(executeBeforeActionChain.firstCall.args[0]).to.be.a(
            TestBeforeActionsController
          )

          executeAction.restore()
          executeBeforeActionChain.restore()

          done()

      it 'should call executeAction after with exactly the same arguments', (done) ->
        executeAction = sinon.spy dispatcher, 'executeAction'

        Backbone.trigger 'matchRoute', route, params, routeOptions

        loadBeforeActionsAndExecute ->
          args = executeAction.firstCall.args

          expect(args).to.have.length 5
          expect(args[0]).to.be.a TestBeforeActionsController
          expect(args[1]).to.be 'test_before_actions'
          expect(args[2]).to.be 'show'
          expect(args[3]).to.be.an 'object'
          expect(args[4]).to.be.an 'object'

          executeAction.restore()

          done()

      it 'should run all defined before actions when running an action', ->
        called = []

        class TestController extends Controller
          beforeAction:
            show: -> called.push 'showBeforeAction'
            'show*': 'beforeShow'
            create: -> called.push 'createBeforeAction'

          show: ->

          create: ->

          beforeShow: ->
            called.push 'showWildcardBeforeAction'

        controller = new TestController()

        dispatcher.executeBeforeActionChain controller, 'test', 'show',
          params, routeOptions

        expect(called).to.have.length 2
        expect(called).to.contain 'showBeforeAction'
        expect(called).to.contain 'showWildcardBeforeAction'

        called = []

        dispatcher.executeBeforeActionChain controller, 'test', 'create',
          params, routeOptions

        expect(called).to.have.length 1
        expect(called).to.contain 'createBeforeAction'

      it 'should run all before actions of the whole prototype chain in correct order', ->

        class BaseController extends Controller
          beforeAction:
            '.*': 'loadSession'

          loadSession: ->
            userModel = isAdmin: -> true

        class AdminController extends BaseController

          beforeAction:
            '.*': 'checkAdminPrivileges'

          checkAdminPrivileges: (params, userModel) ->
            unless userModel.isAdmin()
              @redirectTo '500'

        class UserBanningController extends AdminController

          beforeAction:
            index: 'loadUsers'

          index: ->

          loadUsers: ->

        loadSession = sinon.spy BaseController.prototype, 'loadSession'
        checkAdminPrivileges = sinon.spy AdminController.prototype,
          'checkAdminPrivileges'
        loadUsers = sinon.spy UserBanningController.prototype, 'loadUsers'

        controller = new UserBanningController()
        dispatcher.executeBeforeActionChain controller, 'user_banning',
          'index', params, routeOptions

        expect(loadSession).was.called()
        expect(checkAdminPrivileges).was.called()
        expect(loadUsers).was.called()

        expect(loadSession).was.calledOn controller
        expect(checkAdminPrivileges).was.calledOn controller
        expect(loadUsers).was.calledOn controller

        expect(loadSession.calledBefore(checkAdminPrivileges)).to.be true
        expect(checkAdminPrivileges.calledBefore(loadUsers)).to.be true

      it 'should throw an error if a before action method isn’t a function or a string', ->

        class BrokenBeforeActionController extends Controller
          beforeAction:
            index: new Date()

          index: ->

        controller = new BrokenBeforeActionController()

        failFn = ->
          dispatcher.executeBeforeActionChain controller, 'broken_before_action',
            'index', params, routeOptions

        expect(failFn).to.throwError()

      it 'should handle sync. before actions then pass the params and the returned value', ->
        previousReturnValueToCheck = null

        class BeforeActionChainController extends Controller
          beforeAction:
            '.*': (params) ->
              params.bar = 'qux'
              # This return value should be passed to next before action in the chain
              'foo'
            show: (params, previousReturnValue) ->
              previousReturnValueToCheck = previousReturnValue

          show: ->

        controller = new BeforeActionChainController()
        dispatcher.executeBeforeActionChain controller,
          'before_action_chain', 'show', params, routeOptions
        expect(params.bar).to.be 'qux'

        # This is done here to ensure the method before actions are actually
        # run synchronous and not asynchronous.
        expect(previousReturnValueToCheck).to.be 'foo'

      it 'should handle single async. before action', ->
        deferred = $.Deferred()

        class AsyncBeforeActionChainController extends Controller

          historyURL: -> 'foo'

          beforeAction:
            '.*': ->
              # Returning a promise here triggers asynchronous behavior.
              deferred.promise()

          show: ->

        controller = new AsyncBeforeActionChainController()

        action = sinon.spy controller, 'show'

        dispatcher.executeBeforeActionChain controller,
          'async_before_action_chain', 'show', params, routeOptions

        expect(action).was.notCalled()

        # Resolve the Deferred
        deferred.resolve()

        expect(action).was.calledOnce()

      it 'should handle async. before actions, then pass the returned value', ->
        deferred = $.Deferred()
        promise = deferred.promise()
        resolveArgument = foo: 'bar'

        class AsyncBeforeActionChainController extends Controller
          beforeAction:
            '.*': ->
              # Returning a promise here triggers asynchronous behavior.
              promise
            show: ->

          show: ->

        controller = new AsyncBeforeActionChainController()

        action = sinon.spy controller, 'show'
        beforeAction = sinon.spy controller.beforeAction, 'show'

        dispatcher.executeBeforeActionChain controller,
          'async_before_action_chain', 'show', params, routeOptions

        expect(beforeAction).was.notCalled()
        expect(action).was.notCalled()

        # Resolve the Deferred
        deferred.resolve resolveArgument

        expect(beforeAction).was.calledOnce()
        expect(beforeAction).was.calledWith params, resolveArgument

        expect(action).was.calledOnce()
