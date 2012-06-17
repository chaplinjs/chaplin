define [
  'underscore'
  'chaplin/mediator'
  'chaplin/application'
  'chaplin/lib/router'
  'chaplin/dispatcher'
  'chaplin/views/layout'
], (_, mediator, Application, Router, Dispatcher, Layout) ->
  'use strict'

  describe 'Application', ->
    #console.debug 'Application spec'

    app = new Application()

    it 'should be a simple object', ->
      expect(_.isObject app).toBe true
      expect(app instanceof Application).toBe true

    it 'should be extendable', ->
      expect(typeof Application.extend).toBe 'function'

      DerivedApplication = Application.extend()
      derivedApp = new DerivedApplication()
      expect(derivedApp instanceof Application).toBe true

    it 'should initialize', ->
      expect(typeof app.initialize).toBe 'function'
      app.initialize()

    it 'should create a dispatcher', ->
      expect(typeof app.initDispatcher).toBe 'function'
      app.initDispatcher()
      expect(app.dispatcher instanceof Dispatcher).toBe true

    it 'should create a layout', ->
      expect(typeof app.initLayout).toBe 'function'
      app.initLayout()
      expect(app.layout instanceof Layout).toBe true

    it 'should create a router', ->
      passedMatch = null
      routesCalled = false
      routes = (match) ->
        routesCalled = true
        passedMatch = match

      expect(typeof app.initRouter).toBe 'function'
      expect(app.initRouter.length).toBe 2
      app.initRouter routes, root: '/test/'

      expect(app.router instanceof Router).toBe true
      expect(routesCalled).toBe true
      expect(typeof passedMatch).toBe 'function'

    it 'should start Backbone.history', ->
      expect(Backbone.History.started).toBe true

    it 'should dispose itself correctly', ->
      expect(typeof app.dispose).toBe 'function'
      app.dispose()

      for prop in ['dispatcher', 'layout', 'router']
        expect(_(app).has prop).toBe false

      expect(app.disposed).toBe true
      if Object.isFrozen
        expect(Object.isFrozen(app)).toBe true
