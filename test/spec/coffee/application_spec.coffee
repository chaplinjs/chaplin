define [
  'chaplin/mediator'
  'chaplin/application'
  'chaplin/lib/router'
  'chaplin/dispatcher'
  'chaplin/views/layout'
], (mediator, Application, Router, Dispatcher, Layout) ->
  'use strict'

  describe 'Application', ->
    #console.debug 'Application spec'

    application = new Application()

    it 'should be a simple object', ->
      expect(typeof application).toBe 'object'
      expect(application instanceof Application).toBe true

    it 'should initialize', ->
      expect(typeof application.initialize).toBe 'function'
      application.initialize()

    it 'should create a dispatcher', ->
      expect(application.dispatcher instanceof Dispatcher)
        .toBe true

    it 'should create a layout', ->
      expect(application.layout instanceof Layout)
        .toBe true

    it 'should create a router', ->
      passedMatch = null
      routesCalled = false
      routes = (match) ->
        routesCalled = true
        passedMatch = match

      expect(typeof application.initRouter).toBe 'function'
      expect(application.initRouter.length).toBe 2
      application.initRouter routes, root: '/test/'

      expect(application.router instanceof Router).toBe true
      expect(routesCalled).toBe true
      expect(typeof passedMatch).toBe 'function'

    it 'should start Backbone.history', ->
      expect(Backbone.History.started).toBe true

    it 'should be disposable', ->
      expect(typeof application.dispose).toBe 'function'
      application.dispose()

      expect(application.dispatcher).toBe null
      expect(application.layout).toBe null
      expect(application.router).toBe null

      expect(application.disposed).toBe true
      if Object.isFrozen
        expect(Object.isFrozen(application)).toBe true
