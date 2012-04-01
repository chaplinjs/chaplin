define [
  'mediator', 'lib/router', 'application', 'controllers/controller', 'controllers/application_controller'
], (mediator, Router, Application, Controller, ApplicationController) ->
  'use strict'

  describe 'ApplicationController', ->
    #console.debug 'ApplicationController spec'

    initializeCalled = actionCalled = historyURLCalled = false
    params = passedParams = undefined

    # Fake route object, walks like a route and swims like a route
    route = controller: 'test', action: 'show'

    # Define a test controller
    class TestController extends Controller

      historyURL: (params) ->
        #console.debug 'TestController#historyURL'
        historyURLCalled = true
        'test/' + (params.id or '')

      initialize: ->
        #console.debug 'TestController#initialize'
        initializeCalled = true

      show: (params) ->
        #console.debug 'TestController#show', params
        actionCalled = true
        passedParams = params

    # Define a test controller module
    define 'controllers/test_controller', (Controller) -> TestController

    beforeEach ->
      # Create a fresh params object which does not equal the previous one
      params = changeURL: false, id: Math.random().toString().replace('0.', '')

    it 'should dispatch routes to controller actions', ->
      mediator.publish 'matchRoute', route, params
      expect(initializeCalled).toBe true
      expect(actionCalled).toBe true
      expect(historyURLCalled).toBe true
      expect(passedParams).toBe params

    it 'should save the current controller, action and params', ->
      mediator.publish 'matchRoute', route, params
      c = Application.applicationController
      expect(c.previousControllerName).toBe 'test'
      expect(c.currentControllerName).toBe 'test'
      expect(c.currentController instanceof TestController).toBe true
      expect(c.currentAction).toBe 'show'
      expect(c.currentParams).toBe params
      expect(c.url).toBe "test/#{params.id}"

    it 'should publish startupController events', ->
      passedEvent = undefined
      handler = (event) ->
        passedEvent = event

      mediator.subscribe 'startupController', handler
      mediator.publish 'matchRoute', route, params
      mediator.unsubscribe 'startupController', handler

      expect(typeof passedEvent).toBe 'object'
      expect(passedEvent.controller instanceof TestController).toBe true
      expect(passedEvent.controllerName).toBe 'test'
      expect(passedEvent.params).toBe params
      expect(passedEvent.previousControllerName).toBe 'test'
