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

    params = undefined

    # Unique ID counter for creating params objects
    paramsId = 0

    # Fake route object, walks like a route and swims like a route
    route = controller: 'test', action: 'show'

    # Reset helpers

    freshParams = ->
      # Create a fresh params object which does not equal the previous one
      params = changeURL: false, id: paramsId++

    # Define a test controller
    class TestController extends Controller

      historyURL: (params) ->
        #console.debug 'TestController#historyURL'
        'test/' + (params.id or '')

      initialize: (params, oldControllerName) ->
        #console.debug 'TestController#initialize', params, oldControllerName
        super

      show: (params, oldControllerName) ->
        #console.debug 'TestController#show', params, oldControllerName

      dispose: (params, newControllerName) ->
        #console.debug 'TestController#dispose'
        super

    # Define a test controller module
    define 'controllers/test_controller', (Controller) -> TestController

    beforeEach ->
      freshParams()

    it 'should initialize', ->
      applicationController = new ApplicationController()

    it 'should dispatch routes to controller actions', ->
      proto = TestController.prototype
      historyURL = spyOn(proto, 'historyURL').andCallThrough()
      initialize = spyOn(proto, 'initialize').andCallThrough()
      action     = spyOn(proto, 'show').andCallThrough()

      mediator.publish 'matchRoute', route, params

      expect(initialize).toHaveBeenCalledWith params, null
      expect(action).toHaveBeenCalledWith params, null
      expect(historyURL).toHaveBeenCalledWith params

    it 'should start a controller anyway when forced', ->
      mediator.publish 'matchRoute', route, params

      proto = TestController.prototype
      historyURL = spyOn(proto, 'historyURL').andCallThrough()
      initialize = spyOn(proto, 'initialize').andCallThrough()
      action     = spyOn(proto, 'show').andCallThrough()

      params.forceStartup = true
      mediator.publish 'matchRoute', route, params

      expect(initialize).toHaveBeenCalledWith params, 'test'
      expect(initialize.callCount).toBe 1
      expect(action).toHaveBeenCalledWith params, 'test'
      expect(action.callCount).toBe 1
      expect(historyURL).toHaveBeenCalledWith params
      expect(historyURL.callCount).toBe 1

    it 'should save the controller, action, params and url', ->
      mediator.publish 'matchRoute', route, params
      c = applicationController
      expect(c.previousControllerName).toBe 'test'
      expect(c.currentControllerName).toBe 'test'
      expect(c.currentController instanceof TestController).toBe true
      expect(c.currentAction).toBe 'show'
      expect(c.currentParams).toBe params
      expect(c.url).toBe "test/#{params.id}"

    it 'should dispose inactive controllers and fire beforeControllerDispose events', ->
      dispose = spyOn(TestController.prototype, 'dispose').andCallThrough()
      beforeControllerDispose = jasmine.createSpy()
      mediator.subscribe 'beforeControllerDispose', beforeControllerDispose

      mediator.publish 'matchRoute', route, params

      expect(dispose).toHaveBeenCalledWith params, 'test'
      passedController = beforeControllerDispose.mostRecentCall.args[0]
      expect(passedController instanceof TestController).toBe true
      expect(passedController.disposed).toBe true

      mediator.unsubscribe 'beforeControllerDispose', beforeControllerDispose

    it 'should publish startupController events', ->
      startupController = jasmine.createSpy()

      mediator.subscribe 'startupController', startupController
      mediator.publish 'matchRoute', route, params

      passedEvent = startupController.mostRecentCall.args[0]
      expect(typeof passedEvent).toBe 'object'
      expect(passedEvent.controller instanceof TestController).toBe true
      expect(passedEvent.controllerName).toBe 'test'
      expect(passedEvent.params).toBe params
      expect(passedEvent.previousControllerName).toBe 'test'

      mediator.unsubscribe 'startupController', startupController

    it 'should be disposable', ->
      expect(typeof applicationController.dispose).toBe 'function'
      applicationController.dispose()

      initialize = spyOn(TestController.prototype, 'initialize')
      mediator.publish 'matchRoute', route, params
      expect(initialize).not.toHaveBeenCalled()

      expect(applicationController.disposed).toBe true
      if Object.isFrozen
        expect(Object.isFrozen(applicationController)).toBe true
