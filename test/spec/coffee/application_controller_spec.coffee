define [
  'mediator',
  'chaplin/controllers/controller',
  'chaplin/controllers/application_controller'
], (mediator, Controller, ApplicationController) ->
  'use strict'

  describe 'ApplicationController', ->
    #console.debug 'ApplicationController spec'

    # Initialize shared variables
    applicationController = undefined

    initializeCalled = actionCalled =
      historyURLCalled = disposeCalled = undefined
    params = passedParams = undefined

    # Unique ID counter for creating params objects
    paramsId = 0

    # Fake route object, walks like a route and swims like a route
    route = controller: 'test', action: 'show'

    # Reset helpers

    resetFlags = ->
      initializeCalled = actionCalled =
        historyURLCalled = disposeCalled = false

    freshParams = ->
      # Create a fresh params object which does not equal the previous one
      params = changeURL: false, id: paramsId++
      passedParams = undefined

    # Clear the mediator
    mediator.unsubscribe()

    # Define a test controller
    class TestController extends Controller

      historyURL: (params) ->
        #console.debug 'TestController#historyURL'
        historyURLCalled = true
        'test/' + (params.id or '')

      initialize: ->
        #console.debug 'TestController#initialize'
        super
        initializeCalled = true

      show: (params) ->
        #console.debug 'TestController#show', params
        actionCalled = true
        passedParams = params

      dispose: ->
        disposeCalled = true
        super

    # Define a test controller module
    define 'controllers/test_controller', (Controller) -> TestController

    beforeEach ->
      resetFlags()
      freshParams()

    it 'should initialize', ->
      applicationController = new ApplicationController()

    it 'should dispatch routes to controller actions', ->
      mediator.publish 'matchRoute', route, params
      expect(initializeCalled).toBe true
      expect(actionCalled).toBe true
      expect(historyURLCalled).toBe true
      expect(passedParams).toBe params

    it 'should start a controller anyway when forced', ->
      mediator.publish 'matchRoute', route, params
      resetFlags()
      params.forceStartup = true
      mediator.publish 'matchRoute', route, params

      expect(initializeCalled).toBe true
      expect(actionCalled).toBe true
      expect(historyURLCalled).toBe true
      expect(passedParams).toBe params

    it 'should save the current controller, action and params', ->
      mediator.publish 'matchRoute', route, params
      c = applicationController
      expect(c.previousControllerName).toBe 'test'
      expect(c.currentControllerName).toBe 'test'
      expect(c.currentController instanceof TestController).toBe true
      expect(c.currentAction).toBe 'show'
      expect(c.currentParams).toBe params
      expect(c.url).toBe "test/#{params.id}"

    it 'should dispose inactive controllers', ->
      passedController = undefined
      beforeControllerDispose = (controller) ->
        passedController = controller
      mediator.subscribe 'beforeControllerDispose', beforeControllerDispose

      mediator.publish 'matchRoute', route, params
      expect(disposeCalled).toBe true
      expect(passedController instanceof TestController).toBe true
      expect(passedController.disposed).toBe true

      mediator.unsubscribe 'beforeControllerDispose', beforeControllerDispose

    it 'should publish startupController events', ->
      passedEvent = undefined
      startupController = (event) ->
        passedEvent = event

      mediator.subscribe 'startupController', startupController
      mediator.publish 'matchRoute', route, params

      expect(typeof passedEvent).toBe 'object'
      expect(passedEvent.controller instanceof TestController).toBe true
      expect(passedEvent.controllerName).toBe 'test'
      expect(passedEvent.params).toBe params
      expect(passedEvent.previousControllerName).toBe 'test'

      mediator.unsubscribe 'startupController', startupController

    it 'should be disposable', ->
      expect(typeof applicationController.dispose).toBe 'function'
      applicationController.dispose()

      mediator.publish 'matchRoute', route, params
      expect(initializeCalled).toBe false

      expect(applicationController.disposed).toBe true
      if Object.isFrozen
        expect(Object.isFrozen(applicationController)).toBe true