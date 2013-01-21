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
    dispatcher = params = options = null

    # Fake route objects, walk like a route and swim like a route

    route1 = controller: 'test1', action: 'show'
    route2 = controller: 'test2', action: 'show'

    redirectToURLRoute = controller: 'test1', action: 'redirectToURL'
    redirectToControllerRoute = controller: 'test1', action: 'redirectToController'

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

    # Reset helpers

    # Create fresh params and options
    refreshParams = ->
      params = id: _.uniqueId('paramsId')
      options = changeURL: false, path: "test/#{params.id}"

    beforeEach refreshParams


    it 'should dispatch routes to controller actions', (done) ->
      proto = Test1Controller.prototype
      initialize = sinon.spy proto, 'initialize'
      action     = sinon.spy proto, 'show'

      mediator.publish 'matchRoute', route1, params, options

      loadTest1Controller ->
        expect(initialize).was.calledWith params, options
        expect(action).was.calledWith params, options

        expect(options.previousControllerName).to.be null

        initialize.restore()
        action.restore()
        done()

    it 'should not start the same controller if params match', (done)->
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
      mediator.publish 'matchRoute', route1, params, options

      proto = Test1Controller.prototype
      initialize = sinon.spy proto, 'initialize'
      action     = sinon.spy proto, 'show'

      refreshParams()
      mediator.publish 'matchRoute', route1, params, options

      loadTest1Controller ->
        expect(initialize).was.calledWith params, options
        expect(action).was.calledWith params, options

        initialize.restore()
        action.restore()

        done()

    it 'should start the same controller if forced', (done) ->
      mediator.publish 'matchRoute', route1, params, options

      proto = Test1Controller.prototype
      initialize = sinon.spy proto, 'initialize'
      action     = sinon.spy proto, 'show'

      options.forceStartup = true
      mediator.publish 'matchRoute', route1, params, options

      loadTest1Controller ->
        expect(initialize).was.calledWith params, options
        expect(action).was.calledWith params, options

        initialize.restore()
        action.restore()

        done()

    it 'should save the controller, action, params and url', (done) ->
      mediator.publish 'matchRoute', route1, params, options
      mediator.publish 'matchRoute', route2, params, options

      # Check that previous route is saved
      loadTest2Controller ->
        d = dispatcher
        expect(d.previousControllerName).to.be 'test1'
        expect(d.currentControllerName).to.be 'test2'
        expect(d.currentController).to.be.a Test2Controller
        expect(d.currentAction).to.be 'show'
        expect(d.currentParams).to.be params
        expect(d.url).to.be "test/#{params.id}"

        done()

    it 'should add the previous controller name to the routing options', (done) ->
      expect(options.previousControllerName).to.be undefined
      mediator.publish 'matchRoute', route1, params, options
      mediator.publish 'matchRoute', route2, params, options

      loadTest1Controller -> loadTest2Controller ->
        expect(options.previousControllerName).to.be 'test1'

        done()

    it 'should dispose inactive controllers', (done) ->
      dispose = sinon.spy Test1Controller.prototype, 'dispose'
      mediator.publish 'matchRoute', route1, params, options
      mediator.publish 'matchRoute', route2, params, options

      loadTest2Controller ->
        # It should pass the params and the new controller name
        expect(dispose).was.calledWith params, 'test2'

        dispose.restore()

        done()

    it 'should fire beforeControllerDispose events', (done) ->
      mediator.publish 'matchRoute', route1, params, options

      beforeControllerDispose = sinon.spy()
      mediator.subscribe 'beforeControllerDispose', beforeControllerDispose

      # Now route to Test2Controller
      mediator.publish 'matchRoute', route2, params, options

      loadTest2Controller ->
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

      loadTest1Controller ->
        expect(startupController).was.calledTwice()

        args = startupController.firstCall.args
        expect(args.length).to.be 1
        passedEvent = args[0]
        expect(passedEvent).to.be.an 'object'
        expect(passedEvent.previousControllerName).to.be null
        expect(passedEvent.controller).to.be.a Test1Controller
        expect(passedEvent.controllerName).to.be 'test1'
        expect(passedEvent.params).to.be params
        expect(passedEvent.options).to.be options

        args = startupController.secondCall.args
        expect(args.length).to.be 1
        passedEvent = args[0]
        expect(passedEvent).to.be.an 'object'
        expect(passedEvent.previousControllerName).to.be 'test1'
        expect(passedEvent.controller).to.be.a Test2Controller
        expect(passedEvent.controllerName).to.be 'test2'
        expect(passedEvent.params).to.be params
        expect(passedEvent.options).to.be options

        mediator.unsubscribe 'startupController', startupController

        done()

    it 'should adjust the URL and pass route options', (done) ->
      spy = sinon.spy()
      mediator.subscribe '!router:changeURL', spy

      options = path: 'my-little-path'
      mediator.publish 'matchRoute', route1, params, options

      loadTest1Controller ->
        expect(spy).was.calledWith options.path, options

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

    it 'should use add the query string when adjusting the URL', (done) ->
      spy = sinon.spy()
      mediator.subscribe '!router:changeURL', spy

      options = path: 'my-little-path', queryString: '?foo=bar'
      mediator.publish 'matchRoute', route1, params, options

      loadTest1Controller ->
        expect(spy).was.calledWith "#{options.path}?#{options.queryString}",
          options

        mediator.unsubscribe '!router:changeURL', spy

        done()

    it 'should support redirection to a URL', (done) ->
      startupController = sinon.spy()
      mediator.subscribe 'startupController', startupController

      # Open a route to check if previous controller info is correct after
      # redirection
      mediator.publish 'matchRoute', route1, params, options
      refreshParams()

      # Open another route that redirects somewhere
      action = sinon.spy Test1Controller.prototype, 'redirectToURL'
      mediator.publish 'matchRoute', redirectToURLRoute, params, options

      loadTest1Controller ->
        expect(action).was.calledWith params, options

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

      route = controller: 'before_actions', action: 'show'

      class BeforeActionsController extends Controller

        beforeAction:
          show: ->
          index: ->

        show: ->

        index: ->

      # Define controller AMD module
      beforeActionsModule = 'controllers/before_actions_controller'
      define beforeActionsModule, -> BeforeActionsController

      # Helpers for asynchronous tests
      loadBeforeActionsController = (callback) ->
        require [beforeActionsModule], callback

      it 'should not run executeAction directly if before actions are present', (done) ->
        executeAction = sinon.spy dispatcher, 'executeAction'
        # Replace executeBeforeActions with a no-op stub
        executeBeforeActions = sinon.stub dispatcher, 'executeBeforeActions'

        mediator.publish 'matchRoute', route, params, options

        loadBeforeActionsController ->
          expect(executeAction).was.notCalled()
          expect(executeBeforeActions).was.called()
          expect(executeBeforeActions.firstCall.args[0]).to.be.a(
            BeforeActionsController
          )

          executeAction.restore()
          executeBeforeActions.restore()

          done()

      it 'should call executeAction after with exactly the same arguments', (done) ->
        executeAction = sinon.spy dispatcher, 'executeAction'

        mediator.publish 'matchRoute', route, params, options

        loadBeforeActionsController ->
          args = executeAction.firstCall.args
          expect(args).to.have.length 5
          expect(args[0]).to.be.a BeforeActionsController
          expect(args[1]).to.be 'before_actions'
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

        dispatcher.executeBeforeActions controller, 'test', 'show',
          params, options

        expect(called).to.have.length 2
        expect(called).to.contain 'showBeforeAction'
        expect(called).to.contain 'showWildcardBeforeAction'

        called = []

        dispatcher.executeBeforeActions controller, 'test', 'create',
          params, options

        expect(called).to.have.length 1
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

        class UserBanningController extends AdminController

          beforeAction:
            index: 'loadUsers'

          loadUsers: ->

          index: ->

        loadSession = sinon.spy BaseController.prototype, 'loadSession'
        checkAdminPrivileges = sinon.spy AdminController.prototype,
          'checkAdminPrivileges'
        loadUsers = sinon.spy UserBanningController.prototype, 'loadUsers'
        indexAction = sinon.spy UserBanningController.prototype, 'index'

        controller = new UserBanningController()
        dispatcher.executeBeforeActions controller, 'user_banning',
          'index', params, options

        expect(loadSession).was.calledWith params
        expect(checkAdminPrivileges).was.calledWith params, options, userModel
        expect(loadUsers).was.calledWith params
        expect(indexAction).was.calledWith params

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
          dispatcher.executeBeforeActions controller, 'broken_before_action',
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

        dispatcher.executeBeforeActions controller,
          'before_action_chain', 'show', params, options

        expect(params.bar).to.be 'qux'
        expect(options.bar).to.be 'qux'

        # Ensure the before actions are run synchronous
        expect(showBeforeAction).was.calledWith params, options, 'foo'

      it 'should handle single async. before action', ->
        deferred = $.Deferred()
        promise = deferred.promise()

        class AsyncBeforeActionController extends Controller

          beforeAction:
            '.*': ->
              promise

          show: ->

        controller = new AsyncBeforeActionController()

        action = sinon.spy controller, 'show'

        dispatcher.executeBeforeActions controller,
          'async_before_action', 'show', params, options

        expect(action).was.notCalled()

        # Resolve the Deferred
        deferred.resolve()

        expect(action).was.calledOnce()

      it 'should handle async. before actions, then pass the returned value', ->
        deferred = $.Deferred()
        promise = deferred.promise()
        resolveArgument = foo: 'bar'

        class AsyncBeforeActionController extends Controller

          beforeAction:
            '.*': ->
              promise
            show: ->

          show: ->

        controller = new AsyncBeforeActionController()

        action = sinon.spy controller, 'show'
        beforeAction = sinon.spy controller.beforeAction, 'show'

        dispatcher.executeBeforeActions controller,
          'async_before_action', 'show', params, options

        expect(beforeAction).was.notCalled()
        expect(action).was.notCalled()

        # Resolve the Deferred
        deferred.resolve resolveArgument

        expect(beforeAction).was.calledOnce()
        expect(beforeAction).was.calledWith params, options, resolveArgument

        expect(action).was.calledOnce()
        expect(action).was.calledWith params

      it 'should stop async. dispatching when another controller is started', (done) ->
        deferred = $.Deferred()
        promise = deferred.promise()

        firstRoute = controller: 'neverending', action: 'show'
        secondRoute = controller: 'before_actions', action: 'index'

        class NeverendingController extends Controller

          beforeAction:
            '.*': ->
              promise
            show: ->

          show: ->

        # Define controller AMD module
        neverendingModule = 'controllers/neverending_controller'
        define neverendingModule, -> NeverendingController
        loadNeverendingController = (callback) ->
          require [neverendingModule], callback

        # Spies
        indexAction = sinon.spy BeforeActionsController.prototype, 'index'
        proto = NeverendingController.prototype
        beforeShowAction = sinon.spy proto.beforeAction, 'show'
        showAction = sinon.spy proto, 'show'

        # Start with the neverending controller
        mediator.publish 'matchRoute', firstRoute, params, options

        loadNeverendingController ->
          # While waiting for the promise, start another controller
          mediator.publish 'matchRoute', secondRoute, params, options

          loadBeforeActionsController ->
            expect(indexAction).was.called()

            deferred.resolve()
            expect(beforeShowAction).was.notCalled()
            expect(showAction).was.notCalled()

            indexAction.restore()
            beforeShowAction.restore()
            showAction.restore()
            require.undef neverendingModule

            done()
