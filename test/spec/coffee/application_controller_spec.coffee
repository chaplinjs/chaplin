define [
  'mediator', 'controllers/controller', 'controllers/application_controller'
], (mediator, Controller, ApplicationController) ->
  'use strict'

  describe 'ApplicationController', ->
    #console.debug 'ApplicationController spec'

    applicationController = undefined

    initializeCalled = actionCalled =
      historyURLCalled = disposeCalled = undefined
    params = passedParams = undefined
    # Unique ID counter for creating params objects
    paramsId = 0

    resetFlags = ->
      initializeCalled = actionCalled =
        historyURLCalled = disposeCalled = false

    freshParams = ->
      # Create a fresh params object which does not equal the previous one
      params = changeURL: false, id: paramsId++
      passedParams = undefined

    # Fake route object, walks like a route and swims like a route
    route = controller: 'test', action: 'show'

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

    it 'should dispose old controllers', ->
      controller = undefined
      handler = (passedController) ->
        controller = passedController
      mediator.subscribe 'beforeControllerDispose', handler
      mediator.publish 'matchRoute', route, params

    it 'should save the current controller, action and params', ->
      mediator.publish 'matchRoute', route, params
      c = applicationController
      expect(c.previousControllerName).toBe 'test'
      expect(c.currentControllerName).toBe 'test'
      expect(c.currentController instanceof TestController).toBe true
      expect(c.currentAction).toBe 'show'
      expect(c.currentParams).toBe params
      expect(c.url).toBe "test/#{params.id}"

    it 'should publish startupController events', ->
      event = undefined
      handler = (passedEvent) ->
        event = passedEvent

      mediator.subscribe 'startupController', handler
      mediator.publish 'matchRoute', route, params
      mediator.unsubscribe 'startupController', handler

      expect(typeof event).toBe 'object'
      expect(event.controller instanceof TestController).toBe true
      expect(event.controllerName).toBe 'test'
      expect(event.params).toBe params
      expect(event.previousControllerName).toBe 'test'
