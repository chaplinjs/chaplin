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
    dispatcher = params = options = stdOptions = null

    # Fake route objects, walk like a route and swim like a route

    route1 = controller: 'test1', action: 'show'
    route2 = controller: 'test2', action: 'show'

    redirectToURLRoute =
      controller: 'test1', action: 'redirectToURL'
    redirectToControllerRoute =
       controller: 'test1', action: 'redirectToController'

    # Define test controllers

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

    # Define a test controller AMD modules
    test1Module = 'controllers/test1_controller'
    test2Module = 'controllers/test2_controller'
    define test1Module, -> Test1Controller
    define test2Module, -> Test2Controller

    # Helpers for asynchronous tests
    loadTest1Controller = (callback) -> require [test1Module], callback
    loadTest2Controller = (callback) -> require [test2Module], callback

    # Create a fresh Dispatcher instance for each test

    beforeEach ->
      dispatcher = new Dispatcher()

    afterEach ->
      dispatcher.dispose()
      dispatcher = null

    # Default options which are added on first dispatching
    addedOptions =
      changeURL: true
      forceStartup: false
      previousControllerName: null

    # Helper for creating params/options to compare with
    create = ->
      _.extend {}, arguments...

    # Reset helper: Create fresh params and options
    refreshParams = ->
      params = id: _.uniqueId('paramsId')
      path = "test/#{params.id}"
      options = {path}
      stdOptions = create options, addedOptions

    beforeEach refreshParams

    it 'should dispatch routes to controller actions', (done) ->
      proto = Test1Controller.prototype
      initialize = sinon.spy proto, 'initialize'
      action     = sinon.spy proto, 'show'

      mediator.publish 'matchRoute', route1, params, options

      loadTest1Controller ->
        for spy in [initialize, action]
          expect(spy).was.calledOnce()
          args = spy.firstCall.args
          expect(args[0]).to.eql params
          expect(args[1]).to.eql stdOptions

        initialize.restore()
        action.restore()

        done()

    it 'should not start the same controller if params match', (done) ->
      mediator.publish 'matchRoute', route1, params, options

      loadTest1Controller ->
        proto = Test1Controller.prototype
        initialize = sinon.spy proto, 'initialize'
        action     = sinon.spy proto, 'show'

        mediator.publish 'matchRoute', route1, params, options

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

      paramsStore = [params]
      optionsStore = [options]
      mediator.publish 'matchRoute', route1, params, options

      refreshParams()
      paramsStore.push params
      optionsStore.push options
      mediator.publish 'matchRoute', route1, params, options

      loadTest1Controller ->
        expect(initialize).was.calledTwice()
        expect(action).was.calledTwice()

        for i in [0..1]
          for spy in [initialize, action]
            args = spy.args[i]
            expect(args[0]).to.eql paramsStore[i]
            expectedOptions = create optionsStore[i], {
              changeURL: true
              forceStartup: false
              previousControllerName: (if i is 0 then null else 'test1')
            }
            expect(args[1]).to.eql expectedOptions

        initialize.restore()
        action.restore()

        done()

    it 'should start the same controller if forced', (done) ->
      proto = Test1Controller.prototype
      initialize = sinon.spy proto, 'initialize'
      action     = sinon.spy proto, 'show'

      paramsStore = [params]
      optionsStore = [options]
      mediator.publish 'matchRoute', route1, params, options

      refreshParams()
      paramsStore.push params
      optionsStore.push options
      options.forceStartup = true
      mediator.publish 'matchRoute', route1, params, options

      loadTest1Controller ->
        for i in [0..1]
          for spy in [initialize, action]
            args = spy.args[i]
            expect(args[0]).to.eql paramsStore[i]
            expectedOptions = create optionsStore[i], {
              changeURL: true
              forceStartup: (if i is 0 then false else true)
              previousControllerName: (if i is 0 then null else 'test1')
            }
            expect(args[1]).to.eql expectedOptions

        initialize.restore()
        action.restore()

        done()

    it 'should save the controller, action, params and url', (done) ->
      mediator.publish 'matchRoute', route1, params, options
      mediator.publish 'matchRoute', route2, params, options

      # Check that previous route is saved
      loadTest1Controller -> loadTest2Controller ->
        d = dispatcher
        expect(d.previousControllerName).to.be 'test1'
        expect(d.currentControllerName).to.be 'test2'
        expect(d.currentController).to.be.a Test2Controller
        expect(d.currentAction).to.be 'show'
        expect(d.currentParams).to.eql params
        expect(d.url).to.be "test/#{params.id}"

        done()

    it 'should add the previous controller name to the routing options', (done) ->
      action = sinon.spy Test2Controller.prototype, 'show'

      mediator.publish 'matchRoute', route1, params, options
      mediator.publish 'matchRoute', route2, params, options

      loadTest1Controller -> loadTest2Controller ->
        expect(action).was.calledOnce()
        options = action.firstCall.args[1]
        expect(options).to.be.an 'object'
        expect(options.previousControllerName).to.be 'test1'

        action.restore()

        done()

    it 'should dispose inactive controllers', (done) ->
      dispose = sinon.spy Test1Controller.prototype, 'dispose'
      mediator.publish 'matchRoute', route1, params, options
      mediator.publish 'matchRoute', route2, params, options

      loadTest1Controller -> loadTest2Controller ->
        # It should pass the params and the new controller name
        expect(dispose).was.calledOnce()
        args = dispose.firstCall.args
        expect(args[0]).to.eql params
        expect(args[1]).to.be 'test2'

        dispose.restore()

        done()

    it 'should fire beforeControllerDispose events', (done) ->
      mediator.publish 'matchRoute', route1, params, options

      beforeControllerDispose = sinon.spy()
      mediator.subscribe 'beforeControllerDispose', beforeControllerDispose

      # Now route to Test2Controller
      mediator.publish 'matchRoute', route2, params, options

      loadTest1Controller -> loadTest2Controller ->
        expect(beforeControllerDispose).was.calledOnce()
        # Event payload should be the now disposed controller
        passedController = beforeControllerDispose.firstCall.args[0]
        expect(passedController).to.be.a Test1Controller
        expect(passedController.disposed).to.be true

        mediator.unsubscribe 'beforeControllerDispose', beforeControllerDispose

        done()

    it 'should publish startupController events', (done) ->
      startupController = sinon.spy()
      mediator.subscribe 'startupController', startupController

      mediator.publish 'matchRoute', route1, params, options
      mediator.publish 'matchRoute', route2, params, options

      loadTest1Controller -> loadTest2Controller ->
        expect(startupController).was.calledTwice()

        for i in [0..1]
          args = startupController.getCall(i).args
          expect(args.length).to.be 1
          passedEvent = args[0]
          expect(passedEvent).to.be.an 'object'
          expect(passedEvent.previousControllerName).to.be(
            if i is 0 then null else 'test1'
          )
          expect(passedEvent.controller).to.be.a(
            if i is 0 then Test1Controller else Test2Controller
          )
          expect(passedEvent.controllerName).to.be(
            if i is 0 then 'test1' else 'test2'
          )
          expect(passedEvent.params).to.eql params
          expect(passedEvent.options).to.eql(
            if i is 0
              stdOptions
            else
              create(stdOptions, previousControllerName: 'test1')
          )

        mediator.unsubscribe 'startupController', startupController

        done()

    it 'should adjust the URL and pass route options', (done) ->
      spy = sinon.spy()
      mediator.subscribe '!router:changeURL', spy

      path = 'my-little-path'
      options = {path}
      mediator.publish 'matchRoute', route1, params, options

      loadTest1Controller ->
        expect(spy).was.calledOnce()
        args = spy.firstCall.args
        expect(args[0]).to.be path
        expect(args[1]).to.eql create(options, addedOptions)

        mediator.unsubscribe '!router:changeURL', spy

        done()

    it 'should not adjust the URL if not desired', (done) ->
      spy = sinon.spy()
      mediator.subscribe '!router:changeURL', spy

      options = path: 'my-little-path', changeURL: false
      mediator.publish 'matchRoute', route1, params, options

      loadTest1Controller ->
        expect(spy).was.notCalled()

        mediator.unsubscribe '!router:changeURL', spy

        done()

    it 'should add the query string when adjusting the URL', (done) ->
      spy = sinon.spy()
      mediator.subscribe '!router:changeURL', spy

      options = path: 'my-little-path', queryString: '?foo=bar'
      mediator.publish 'matchRoute', route1, params, options

      loadTest1Controller ->
        expect(spy).was.calledOnce()
        args = spy.firstCall.args
        expect(args[0]).to.be "#{options.path}?#{options.queryString}"
        expect(args[1]).to.eql  create(options, addedOptions)

        mediator.unsubscribe '!router:changeURL', spy

        done()

    it 'should support redirection to a URL', (done) ->
      startupController = sinon.spy()
      mediator.subscribe 'startupController', startupController

      # Open a route to check if previous controller info is correct after
      # redirection
      mediator.publish 'matchRoute', route1, params, options

      # Open another route that redirects somewhere
      refreshParams()
      action = sinon.spy Test1Controller.prototype, 'redirectToURL'
      mediator.publish 'matchRoute', redirectToURLRoute, params, options

      loadTest1Controller ->
        expect(action).was.calledOnce()
        args = action.firstCall.args
        expect(args[0]).to.eql params
        expect(args[1]).to.eql create(stdOptions, {
          previousControllerName: 'test1'
        })

        # Don’t expect that the new controller was called
        # because we’re not testing the router. Just test
        # if execution stopped (e.g. Test1Controller is still active)
        d = dispatcher
        expect(d.previousControllerName).to.be 'test1'
        expect(d.currentControllerName).to.be 'test1'
        expect(d.currentController).to.be.a Test1Controller
        expect(d.currentAction).to.be 'show'
        expect(d.currentParams.id).not.to.be params.id
        expect(d.url).not.to.be "test/#{params.id}"

        expect(startupController).was.calledOnce()

        mediator.unsubscribe 'startupController', startupController
        action.restore()

        done()

    it 'should dispose itself correctly', (done) ->
      expect(dispatcher.dispose).to.be.a 'function'
      dispatcher.dispose()

      initialize = sinon.spy Test1Controller.prototype, 'initialize'
      mediator.publish 'matchRoute', route1, params, options

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

      route = controller: 'test_before_actions', action: 'show'

      class TestBeforeActionsController extends Controller

        beforeAction:
          show: ->
          index: ->

        show: ->

        index: ->

      # Define a test controller AMD module
      testBeforeActionsModule = 'controllers/test_before_actions_controller'
      define testBeforeActionsModule, -> TestBeforeActionsController

      # Helpers for asynchronous tests
      loadBeforeActionsController = (callback) ->
        require [testBeforeActionsModule], callback

      it 'should not run executeAction directly if before actions are present', (done) ->
        executeAction = sinon.spy dispatcher, 'executeAction'
        # Replace executeBeforeActionChain with a no-op stub
        executeBeforeActionChain = sinon.stub dispatcher, 'executeBeforeActionChain'

        mediator.publish 'matchRoute', route, params, options

        loadBeforeActionsController ->
          expect(executeAction).was.notCalled()
          expect(executeBeforeActionChain).was.called()
          passedController = executeBeforeActionChain.firstCall.args[0]
          expect(passedController).to.be.a TestBeforeActionsController

          executeAction.restore()
          executeBeforeActionChain.restore()

          done()

      it 'should call executeAction after with exactly the same arguments', (done) ->
        executeAction = sinon.spy dispatcher, 'executeAction'

        mediator.publish 'matchRoute', route, params, options

        loadBeforeActionsController ->
          args = executeAction.firstCall.args
          expect(args.length).to.be 5
          expect(args[0]).to.be.a TestBeforeActionsController
          expect(args[1]).to.be 'test_before_actions'
          expect(args[2]).to.be 'show'
          expect(args[3]).to.eql params
          expect(args[4]).to.eql stdOptions

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
          params, options

        expect(called.length).to.be 2
        expect(called).to.contain 'showBeforeAction'
        expect(called).to.contain 'showWildcardBeforeAction'

        called = []

        dispatcher.executeBeforeActionChain controller, 'test', 'create',
          params, options

        expect(called.length).to.be 1
        expect(called).to.contain 'createBeforeAction'

      it 'should run all before actions of the whole prototype chain in correct order', ->

        userModel = isAdmin: -> true

        class BaseController extends Controller

          beforeAction:
            '.*': 'loadSession'

          loadSession: ->
            userModel

        class AdminController extends BaseController

          beforeAction:
            '.*': 'checkAdminPrivileges'

          checkAdminPrivileges: (params, options, userModel) ->
            unless userModel.isAdmin()
              @redirectTo '500'
            return

        class UserManagerController extends AdminController

          beforeAction:
            index: 'loadUsers'

          loadUsers: ->

          index: ->

        loadSession = sinon.spy BaseController.prototype, 'loadSession'
        checkAdminPrivileges = sinon.spy AdminController.prototype,
          'checkAdminPrivileges'
        loadUsers = sinon.spy UserManagerController.prototype, 'loadUsers'
        indexAction = sinon.spy UserManagerController.prototype, 'index'

        controller = new UserManagerController()
        dispatcher.executeBeforeActionChain controller, 'user_manager',
          'index', params, options

        expect(loadSession).was.calledWith params
        expect(checkAdminPrivileges).was.calledWith params, options, userModel
        expect(loadUsers).was.calledWith params
        expect(indexAction).was.calledWith params

        expect(checkAdminPrivileges.firstCall.args[2]).to.be userModel

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
            'index', params, options

        expect(failFn).to.throwError()

      it 'should handle sync. before actions then pass the params and the returned value', ->
        showBeforeAction = sinon.spy()

        class BeforeActionChainController extends Controller

          beforeAction:
            '.*': (params) ->
              params.bar = 'qux'
              options.bar = 'qux'
              # This return value should be passed to next before action in the chain
              'foo'
            show: showBeforeAction

          show: ->

        controller = new BeforeActionChainController()
        dispatcher.executeBeforeActionChain controller,
          'before_action_chain', 'show', params, options

        expect(params.bar).to.be 'qux'
        expect(options.bar).to.be 'qux'

        # Ensure the before actions are run synchronous
        expect(showBeforeAction).was.calledOnce()
        args = showBeforeAction.firstCall.args
        expect(args[0]).to.eql params
        expect(args[1]).to.eql options
        expect(args[2]).to.eql 'foo'

      it 'should handle single async. before action', ->
        deferred = $.Deferred()
        promise = deferred.promise()

        class AsyncBeforeActionChainController extends Controller

          historyURL: -> 'foo'

          beforeAction:
            '.*': ->
              # Returning a promise here triggers asynchronous behavior.
              promise

          show: ->

        controller = new AsyncBeforeActionChainController()

        action = sinon.spy controller, 'show'

        dispatcher.executeBeforeActionChain controller,
          'async_before_action_chain', 'show', params, options

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
          'async_before_action_chain', 'show', params, options

        expect(beforeAction).was.notCalled()
        expect(action).was.notCalled()

        # Resolve the Deferred
        deferred.resolve resolveArgument

        expectedOptions = create options, {
          previousControllerName: null
        }

        expect(beforeAction).was.calledOnce()
        args = beforeAction.firstCall.args
        expect(args[0]).to.eql params
        expect(args[1]).to.eql expectedOptions
        expect(args[2]).to.be resolveArgument

        expect(action).was.calledOnce()
        args = action.firstCall.args
        expect(args[0]).to.eql params
        expect(args[1]).to.eql expectedOptions

      it 'should not call a deferred callback upon a new route being fired with a different controller', (done) ->
        deferred = $.Deferred()
        promise = deferred.promise()
        route1 = controller: 'test_stalled_before_actions', action: 'show'
        route2 = controller: 'test_before_actions', action: 'index'

        # First order controller
        class TestStalledBeforeActionsController extends Controller

          beforeAction:
            '.*': ->
              promise
            show: ->
              console.log 'show'
              null

          show: ->
            console.log 'show action'

        # Spies
        proto = TestBeforeActionsController.prototype
        indexActionSpy = sinon.spy proto, 'index'
        proto = TestStalledBeforeActionsController.prototype
        beforeActionSpy = sinon.spy proto.beforeAction, 'show'
        # Define a test controller AMD module
        testStalledBeforeActionsModule = 'controllers/test_stalled_before_actions_controller'
        define testStalledBeforeActionsModule, -> TestStalledBeforeActionsController
        # Helpers for asynchronous tests
        loadStalledBeforeActionsController = (callback) ->
          require [testStalledBeforeActionsModule], callback

        mediator.publish 'matchRoute', route1, params, options
        loadStalledBeforeActionsController ->
          mediator.publish 'matchRoute', route2, params, options
          loadBeforeActionsController ->
            expect(indexActionSpy).was.called()

            deferred.resolve()
            expect(beforeActionSpy).was.notCalled()

            beforeActionSpy.restore()
            indexActionSpy.restore()
            done()
