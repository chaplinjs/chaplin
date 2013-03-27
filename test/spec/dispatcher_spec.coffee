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
    dispatcher = params = options = stdOptions = route1 = route2 = null

    # Fake route objects, walk like a route and swim like a route

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

    # Helper for creating params/options to compare with
    create = ->
      _.extend {}, arguments...

    # Reset helper: Create fresh params and options
    refreshParams = ->
      params = id: _.uniqueId('paramsId')
      path = "test/#{params.id}"
      route1 = {controller: 'test1', action: 'show', path}
      route2 = {controller: 'test2', action: 'show', path}
      options = {}
      stdOptions = create addedOptions

    beforeEach refreshParams

    it 'should dispatch routes to controller actions', (done) ->
      proto = Test1Controller.prototype
      initialize = sinon.spy proto, 'initialize'
      action     = sinon.spy proto, 'show'

      mediator.publish 'router:match', route1, params, create options

      loadTest1Controller ->
        for spy in [initialize, action]
          expect(spy).was.calledOnce()
          args = spy.firstCall.args
          expect(args[0]).to.eql params
          expect(args[1].controller).to.eql route1.controller
          expect(args[1].action).to.eql route1.action
          expect(args[2]).to.eql stdOptions

        initialize.restore()
        action.restore()

        done()

    it 'should not start the same controller if params match', (done) ->
      mediator.publish 'router:match', route1, params, options

      loadTest1Controller ->
        proto = Test1Controller.prototype
        initialize = sinon.spy proto, 'initialize'
        action     = sinon.spy proto, 'show'

        mediator.publish 'router:match', route1, params, options

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
      mediator.publish 'router:match', route1, params, options

      refreshParams()
      paramsStore.push params
      optionsStore.push options
      mediator.publish 'router:match', route1, params, options

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
            }
            expect(args[1].controller).to.eql route1.controller
            expect(args[1].action).to.eql route1.action
            if i isnt 0
              expect(args[1].previous.controller).to.eql 'test1'
            expect(args[2]).to.eql expectedOptions

        initialize.restore()
        action.restore()

        done()

    it 'should start the same controller if forced', (done) ->
      proto = Test1Controller.prototype
      initialize = sinon.spy proto, 'initialize'
      action     = sinon.spy proto, 'show'

      paramsStore = [params]
      optionsStore = [options]
      mediator.publish 'router:match', route1, params, options

      refreshParams()
      paramsStore.push params
      optionsStore.push options
      options.forceStartup = true
      mediator.publish 'router:match', route1, params, options

      loadTest1Controller ->
        for i in [0..1]
          for spy in [initialize, action]
            args = spy.args[i]
            expect(args[0]).to.eql paramsStore[i]
            expectedOptions = create optionsStore[i], {
              changeURL: true
              forceStartup: (if i is 0 then false else true)
            }
            expect(args[2]).to.eql expectedOptions

        initialize.restore()
        action.restore()

        done()

    it 'should save the controller, action, params and url', (done) ->
      mediator.publish 'router:match', route1, params, options
      mediator.publish 'router:match', route2, params, options

      # Check that previous route is saved
      loadTest1Controller -> loadTest2Controller ->
        d = dispatcher
        expect(d.previousRoute.controller).to.be 'test1'
        expect(d.currentController).to.be.a Test2Controller
        expect(d.currentRoute.controller).to.be 'test2'
        expect(d.currentRoute.action).to.be 'show'
        expect(d.currentParams).to.eql params
        expect(d.currentRoute.path).to.be "test/#{params.id}"

        done()

    it 'should add the previous controller name to the route', (done) ->
      action = sinon.spy Test2Controller.prototype, 'show'

      mediator.publish 'router:match', route1, params, options
      mediator.publish 'router:match', route2, params, options

      loadTest1Controller -> loadTest2Controller ->
        expect(action).was.calledOnce()
        route = action.firstCall.args[1]
        expect(route).to.be.an 'object'
        expect(route.previous.controller).to.be 'test1'

        action.restore()

        done()

    it 'should dispose inactive controllers', (done) ->
      dispose = sinon.spy Test1Controller.prototype, 'dispose'
      mediator.publish 'router:match', route1, params, options
      mediator.publish 'router:match', route2, params, options

      loadTest1Controller -> loadTest2Controller ->
        # It should pass the params and the new controller name
        expect(dispose).was.calledOnce()
        args = dispose.firstCall.args
        expect(args[0]).to.eql params
        expect(args[1].controller).to.eql route2.controller
        expect(args[1].action).to.eql route2.action
        expect(args[1].path).to.eql route2.path

        dispose.restore()

        done()

    it 'should fire beforeControllerDispose events', (done) ->
      mediator.publish 'router:match', route1, params, options

      beforeControllerDispose = sinon.spy()
      mediator.subscribe 'beforeControllerDispose', beforeControllerDispose

      # Now route to Test2Controller
      mediator.publish 'router:match', route2, params, options

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

      mediator.publish 'router:match', route1, params, options
      mediator.publish 'router:match', route2, params, options

      loadTest1Controller -> loadTest2Controller ->
        expect(dispatch).was.calledTwice()

        for i in [0..1]
          args = dispatch.getCall(i).args
          expect(args.length).to.be 4
          expect(args[2].previous.controller).to.be(
            if i is 0 then undefined else 'test1'
          )
          expect(args[0]).to.be.a(
            if i is 0 then Test1Controller else Test2Controller
          )
          expect(args[2].controller).to.be(
            if i is 0 then 'test1' else 'test2'
          )
          expect(args[1]).to.eql params
          expect(args[3]).to.eql(
            if i is 0
              create(stdOptions)
            else
              create(stdOptions)
          )

        mediator.unsubscribe 'dispatcher:dispatch', dispatch

        done()

    it 'should adjust the URL and pass route options', (done) ->
      spy = sinon.spy()
      mediator.subscribe '!router:changeURL', spy

      path = 'my-little-path'
      options = create {path}
      mediator.publish 'router:match', route1, params, options

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

      options =
        path: 'my-little-path', changeURL: false,
        controller: 'test1', action: 'show'
      mediator.publish 'router:match', route1, params, options

      loadTest1Controller ->
        expect(spy).was.notCalled()

        mediator.unsubscribe '!router:changeURL', spy

        done()

    it 'should add the query string when adjusting the URL', (done) ->
      spy = sinon.spy()
      mediator.subscribe '!router:changeURL', spy

      options =
        path: 'my-little-path', queryString: '?foo=bar',
        controller: 'test1', action: 'show'
      mediator.publish 'router:match', route1, params, options

      loadTest1Controller ->
        expect(spy).was.calledOnce()
        args = spy.firstCall.args
        expect(args[0]).to.be "#{options.path}?#{options.queryString}"
        expect(args[1]).to.eql  create(options, addedOptions)

        mediator.unsubscribe '!router:changeURL', spy

        done()

    it 'should support redirection to a URL', (done) ->
      dispatch = sinon.spy()
      mediator.subscribe 'dispatcher:dispatch', dispatch

      # Open a route to check if previous controller info is correct after
      # redirection
      mediator.publish 'router:match', route1, params, options

      # Open another route that redirects somewhere
      refreshParams()
      action = sinon.spy Test1Controller.prototype, 'redirectToURL'
      mediator.publish 'router:match', redirectToURLRoute, params, options

      loadTest1Controller ->
        expect(action).was.calledOnce()
        args = action.firstCall.args
        expect(args[0]).to.eql params
        expect(args[2]).to.eql create(stdOptions)
        expect(args[1].previous.controller).to.eql 'test1'

        # Don’t expect that the new controller was called
        # because we’re not testing the router. Just test
        # if execution stopped (e.g. Test1Controller is still active)
        d = dispatcher
        expect(d.previousRoute.controller).to.be 'test1'
        expect(d.currentRoute.controller).to.be 'test1'
        expect(d.currentController).to.be.a Test1Controller
        expect(d.currentRoute.action).to.be 'redirectToURL'
        expect(d.currentRoute.path).not.to.be "test/#{params.id}"

        expect(dispatch).was.calledOnce()

        mediator.unsubscribe 'dispatcher:dispatch', dispatch
        action.restore()

        done()

    it 'should dispose when redirecting to a URL', (done) ->
      dispose = sinon.spy Test1Controller.prototype, 'dispose'
      mediator.publish 'router:match', route1, params, options
      mediator.publish 'router:match', redirectToURLRoute, params, options
      loadTest1Controller ->
        expect(dispose).was.calledOnce()
        dispose.restore()
        done()

    it 'should dispose itself correctly', (done) ->
      expect(dispatcher.dispose).to.be.a 'function'
      dispatcher.dispose()

      initialize = sinon.spy Test1Controller.prototype, 'initialize'
      mediator.publish 'router:match', route1, params, options

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

      route = controller: 'before_actions', action: 'show', path: '/'

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

        mediator.publish 'router:match', route, params, options

        loadBeforeActionsController ->
          expect(executeAction).was.notCalled()
          expect(executeBeforeActions).was.called()
          passedController = executeBeforeActions.firstCall.args[0]
          expect(passedController).to.be.a BeforeActionsController

          executeAction.restore()
          executeBeforeActions.restore()

          done()

      it 'should call executeAction after with exactly the same arguments', (done) ->
        executeAction = sinon.spy dispatcher, 'executeAction'

        mediator.publish 'router:match', route, params, options

        loadBeforeActionsController ->
          args = executeAction.firstCall.args
          expect(args.length).to.be 4
          expect(args[0]).to.be.a BeforeActionsController
          expect(args[1].controller).to.be 'before_actions'
          expect(args[1].action).to.be 'show'
          expect(args[2]).to.eql params
          expect(args[3]).to.eql create stdOptions

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

        dispatcher.executeBeforeActions controller, route, params, options

        expect(called.length).to.be 2
        expect(called).to.contain 'showBeforeAction'
        expect(called).to.contain 'showWildcardBeforeAction'

        called = []

        testRoute = controller: 'test', action: 'create'
        dispatcher.executeBeforeActions controller, testRoute, params, options

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

          checkAdminPrivileges: (params, route, options, userModel) ->
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
        testRoute = cotnroller: 'user_manager', action: 'index'
        dispatcher.executeBeforeActions controller, testRoute, params, options

        expect(loadSession).was.calledWith params
        expect(checkAdminPrivileges).was.calledWith params, testRoute,
          options, userModel
        expect(loadUsers).was.calledWith params
        expect(indexAction).was.calledWith params

        expect(checkAdminPrivileges.firstCall.args[3]).to.be userModel

        expect(loadSession.calledBefore(checkAdminPrivileges)).to.be true
        expect(checkAdminPrivileges.calledBefore(loadUsers)).to.be true

      it 'should throw an error if a before action method isn’t a function or a string', ->

        class BrokenBeforeActionController extends Controller

          beforeAction:
            index: new Date()

          index: ->

        controller = new BrokenBeforeActionController()

        failFn = ->
          failRoute = cotnroller: 'broken_before_action', action: 'index'
          dispatcher.executeBeforeActions controller, params, options

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

        testRoute = controller: 'before_action_chain', action: 'show'
        dispatcher.executeBeforeActions controller, testRoute, params, options

        expect(params.bar).to.be 'qux'
        expect(options.bar).to.be 'qux'

        # Ensure the before actions are run synchronous
        expect(showBeforeAction).was.calledOnce()
        args = showBeforeAction.firstCall.args
        expect(args[0]).to.eql params
        expect(args[1]).to.eql testRoute
        expect(args[2]).to.eql options

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

        testRoute = controller: 'async_before_action', action: 'show'
        dispatcher.executeBeforeActions controller, testRoute, params, options

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

        testRoute = controller: 'async_before_action', action: 'show'
        dispatcher.executeBeforeActions controller, testRoute, params, options

        expect(beforeAction).was.notCalled()
        expect(action).was.notCalled()

        # Resolve the Deferred
        deferred.resolve resolveArgument

        expectedOptions = create options

        expect(beforeAction).was.calledOnce()
        args = beforeAction.firstCall.args
        expect(args[0]).to.eql params
        expect(args[1]).to.eql testRoute
        expect(args[2]).to.eql expectedOptions
        expect(args[3]).to.be resolveArgument

        expect(action).was.calledOnce()
        args = action.firstCall.args
        expect(args[0]).to.eql params
        expect(args[1]).to.eql testRoute
        expect(args[2]).to.eql expectedOptions

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
        mediator.publish 'router:match', firstRoute, params, options

        loadNeverendingController ->
          # While waiting for the promise, start another controller
          mediator.publish 'router:match', secondRoute, params, options

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
