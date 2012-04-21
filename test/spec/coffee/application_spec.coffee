define [
  'mediator',
  'chaplin/application',
  'chaplin/lib/router',
  'chaplin/controllers/application_controller',
  'chaplin/views/application_view'
], (mediator, Application, Router, ApplicationController, ApplicationView) ->
  'use strict'

  describe 'Application', ->
    #console.debug 'Application spec'

    application = new Application()

    it 'should be a simple object', ->
      expect(typeof application).toEqual 'object'
      expect(application instanceof Application).toBe true

    it 'should initialize', ->
      expect(typeof application.initialize).toBe 'function'
      application.initialize()

    it 'should create an application controller', ->
      expect(application.applicationController instanceof ApplicationController)
        .toEqual true

    it 'should create an application view', ->
      expect(application.applicationView instanceof ApplicationView)
        .toEqual true

    it 'should create a router', ->
      passedMatch = undefined
      routesCalled = false
      routes = (match) ->
        routesCalled = true
        passedMatch = match

      expect(typeof application.initRouter).toBe 'function'
      application.initRouter routes

      expect(application.router instanceof Router).toEqual true
      expect(routesCalled).toBe true
      expect(typeof passedMatch).toBe 'function'

    it 'should start Backbone.history', ->
      expect(Backbone.History.started).toBe true

    it 'should be disposable', ->
      expect(typeof application.dispose).toBe 'function'
      application.dispose()

      expect(application.applicationController).toBe null
      expect(application.applicationView).toBe null
      expect(application.router).toBe null

      expect(application.disposed).toBe true
      if Object.isFrozen
        expect(Object.isFrozen(application)).toBe true
