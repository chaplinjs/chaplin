define [
  'chaplin'
], (Chaplin) ->
  'use strict'

  describe 'Application', ->
    #console.debug 'Application spec'

    app = new Chaplin.Application()

    it 'should be a simple object', ->
      expect(typeof app).toBe 'object'
      expect(app instanceof Chaplin.Application).toBe true

    it 'should initialize', ->
      expect(typeof app.initialize).toBe 'function'
      app.initialize()

    it 'should create a dispatcher', ->
      expect(typeof app.initDispatcher).toBe 'function'
      app.initDispatcher()
      expect(app.dispatcher instanceof Chaplin.Dispatcher).toBe true

    it 'should create a layout', ->
      expect(typeof app.initLayout).toBe 'function'
      app.initLayout()
      expect(app.layout instanceof Chaplin.Layout).toBe true

    it 'should create a router', ->
      passedMatch = null
      routesCalled = false
      routes = (match) ->
        routesCalled = true
        passedMatch = match

      expect(typeof app.initRouter).toBe 'function'
      expect(app.initRouter.length).toBe 2
      app.initRouter routes, root: '/test/'

      expect(app.router instanceof Chaplin.Router).toBe true
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
